/* ============================================================
   Ads (Google AdMob) — iOS and Android only.
   Web, PWA and desktop builds have no ads; every call here is a
   no-op there and rewarded actions are simply granted.

   Placements:
   - Banner: bottom of the screen on menus and during play.
   - Interstitial: only at a natural break (after a finished
     puzzle, when leaving the result screen), frequency capped.
   - Rewarded: optional — extra hints beyond the free 3, and a
     second chance after losing all lives.

   Ad unit IDs default to Google's public TEST units. Real IDs come
   from build-time env vars (see .env.example and docs/ADS.md).
   ============================================================ */

import { isNative, platform } from './native.js';
import { emit } from '../core/events.js';

const env = import.meta.env || {};

const TEST_UNITS = {
  android: {
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  },
  ios: {
    banner: 'ca-app-pub-3940256099942544/2934735716',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  },
};

function unitsFor(p) {
  const P = p === 'ios' ? 'IOS' : 'ANDROID';
  const t = TEST_UNITS[p] || TEST_UNITS.android;
  return {
    banner: env[`VITE_ADMOB_${P}_BANNER`] || t.banner,
    interstitial: env[`VITE_ADMOB_${P}_INTERSTITIAL`] || t.interstitial,
    rewarded: env[`VITE_ADMOB_${P}_REWARDED`] || t.rewarded,
  };
}

const UNITS = unitsFor(platform);
export const USING_TEST_ADS = Object.values(UNITS).some((id) => id.startsWith('ca-app-pub-3940256099942544/'));

// Frequency caps
const INTERSTITIAL_MIN_GAP_MS = 3 * 60_000;
const INTERSTITIAL_EVERY_N_GAMES = 2;

const state = {
  AdMob: null,
  mod: null,
  ready: false,
  bannerWanted: false,
  bannerShown: false,
  bannerHeight: 0,
  interstitialLoaded: false,
  rewardedLoaded: false,
  lastInterstitialAt: Date.now(), // no interstitial in the first minutes of a session
  gamesSinceInterstitial: 0,
  privacyOptionsRequired: false,
};

export const adsSupported = isNative && (platform === 'ios' || platform === 'android');

function setBannerInset(h) {
  state.bannerHeight = h;
  document.documentElement.style.setProperty('--ad-h', `${h}px`);
  document.documentElement.classList.toggle('has-banner', h > 0);
}

/** Consent → (iOS) tracking prompt → SDK init → preload. Never throws. */
export async function initAds() {
  if (!adsSupported || state.ready) return;
  try {
    state.mod = await import('@capacitor-community/admob');
    const { AdMob, AdmobConsentStatus, BannerAdPluginEvents, InterstitialAdPluginEvents, RewardAdPluginEvents } = state.mod;
    state.AdMob = AdMob;

    let consent = await AdMob.requestConsentInfo();
    if (consent.isConsentFormAvailable && consent.status === AdmobConsentStatus.REQUIRED) {
      consent = await AdMob.showConsentForm();
    }
    state.privacyOptionsRequired = consent.privacyOptionsRequirementStatus === 'REQUIRED';
    if (!consent.canRequestAds) return;

    if (platform === 'ios') {
      try {
        const t = await AdMob.trackingAuthorizationStatus();
        if (t.status === 'notDetermined') await AdMob.requestTrackingAuthorization();
      } catch { /* ignore */ }
    }

    await AdMob.initialize();

    await AdMob.addListener(BannerAdPluginEvents.SizeChanged, (size) => setBannerInset(size?.height > 0 ? size.height : 0));
    await AdMob.addListener(BannerAdPluginEvents.FailedToLoad, () => setBannerInset(0));
    await AdMob.addListener(InterstitialAdPluginEvents.Dismissed, () => { state.interstitialLoaded = false; preloadInterstitial(); });
    await AdMob.addListener(InterstitialAdPluginEvents.FailedToShow, () => { state.interstitialLoaded = false; preloadInterstitial(); });
    await AdMob.addListener(RewardAdPluginEvents.Dismissed, () => { state.rewardedLoaded = false; preloadRewarded(); });

    state.ready = true;
    preloadInterstitial();
    preloadRewarded();
    if (state.bannerWanted) showBanner();
    emit('ads-ready');
  } catch (err) {
    console.warn('[ads] init failed', err);
  }
}

async function preloadInterstitial() {
  if (!state.ready || state.interstitialLoaded) return;
  try { await state.AdMob.prepareInterstitial({ adId: UNITS.interstitial }); state.interstitialLoaded = true; }
  catch { state.interstitialLoaded = false; setTimeout(preloadInterstitial, 60_000); }
}

async function preloadRewarded() {
  if (!state.ready || state.rewardedLoaded) return;
  try { await state.AdMob.prepareRewardVideoAd({ adId: UNITS.rewarded }); state.rewardedLoaded = true; }
  catch { state.rewardedLoaded = false; setTimeout(preloadRewarded, 60_000); }
}

async function showBanner() {
  if (!state.ready || state.bannerShown) return;
  const { BannerAdSize, BannerAdPosition } = state.mod;
  try {
    state.bannerShown = true;
    await state.AdMob.showBanner({
      adId: UNITS.banner,
      adSize: BannerAdSize.ADAPTIVE_BANNER,
      position: BannerAdPosition.BOTTOM_CENTER,
      margin: 0,
    });
  } catch { state.bannerShown = false; setBannerInset(0); }
}

/** Screens call this: true on menus/play, false on full-screen moments. */
export async function setBannerVisible(visible) {
  state.bannerWanted = visible;
  if (!adsSupported || !state.ready) return;
  try {
    if (visible) {
      if (!state.bannerShown) await showBanner();
      else { await state.AdMob.resumeBanner(); }
    } else if (state.bannerShown) {
      await state.AdMob.hideBanner();
      setBannerInset(0);
    }
  } catch { /* ignore */ }
}

/** Count a finished puzzle toward the interstitial cap. */
export function noteGameFinished() { state.gamesSinceInterstitial++; }

/** Show an interstitial if the caps allow. Resolves when it's closed (or skipped). */
export async function maybeShowInterstitial() {
  if (!state.ready || !state.interstitialLoaded) return false;
  if (state.gamesSinceInterstitial < INTERSTITIAL_EVERY_N_GAMES) return false;
  if (Date.now() - state.lastInterstitialAt < INTERSTITIAL_MIN_GAP_MS) return false;
  try {
    await state.AdMob.showInterstitial();
    state.lastInterstitialAt = Date.now();
    state.gamesSinceInterstitial = 0;
    state.interstitialLoaded = false;
    return true;
  } catch { return false; }
}

/**
 * Offer a rewarded ad. Resolves to:
 *   'granted'    — reward earned (or no ads on this platform)
 *   'cancelled'  — player closed it early
 *   'unavailable'— no ad could be loaded; the caller decides (we grant it anyway)
 */
export async function showRewarded() {
  if (!adsSupported) return 'granted';
  if (!state.ready) return 'unavailable';
  if (!state.rewardedLoaded) {
    await preloadRewarded();
    if (!state.rewardedLoaded) return 'unavailable';
  }
  try {
    const reward = await state.AdMob.showRewardVideoAd();
    state.rewardedLoaded = false;
    return reward && (reward.amount > 0 || reward.type) ? 'granted' : 'cancelled';
  } catch {
    state.rewardedLoaded = false;
    return 'unavailable';
  }
}

export function privacyOptionsAvailable() { return adsSupported && state.privacyOptionsRequired; }

export async function showPrivacyOptions() {
  if (!state.AdMob) return;
  try { await state.AdMob.showPrivacyOptionsForm(); } catch { /* ignore */ }
}
