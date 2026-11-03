/* ============================================================
   Alien Sudoku — boot.
   ============================================================ */

import '@fontsource/orbitron/latin-500.css';
import '@fontsource/orbitron/latin-700.css';
import '@fontsource/orbitron/latin-900.css';
import '@fontsource/space-grotesk/latin-400.css';
import '@fontsource/space-grotesk/latin-500.css';
import '@fontsource/space-grotesk/latin-700.css';
import './styles/base.css';
import './styles/play.css';
import './styles/screens.css';

import { initStorage } from './core/storage.js';
import { initProfile, settings } from './core/profile.js';
import { on, emit } from './core/events.js';
import { configureAudio, unlockAudio, setAudioSuspended, sfx } from './audio/audio.js';
import { initPlatform, hideSplash, isNative, isElectron, setHapticsEnabled } from './platform/native.js';
import { initAds } from './platform/ads.js';
import { initBackground } from './ui/background.js';
import { initModals, toast } from './ui/modal.js';
import { initRouter, registerScreen, reset, handleBack } from './ui/router.js';
import { menuScreen } from './ui/screens/menu.js';
import { playScreen } from './ui/screens/play.js';
import { campaignScreen, sectorScreen } from './ui/screens/campaign.js';
import { dailyScreen } from './ui/screens/daily.js';
import { statsScreen, achievementsScreen, howtoScreen } from './ui/screens/info.js';
import { settingsScreen } from './ui/screens/settings.js';
import { SYMBOL_SETS } from './data/symbols.js';

function applySettings() {
  const s = settings();
  configureAudio({ sfx: s.sfx, sfxVolume: s.sfxVolume, music: s.music, musicVolume: s.musicVolume });
  setHapticsEnabled(s.haptics);
  document.documentElement.classList.toggle('reduce-motion', !!s.reduceMotion);
}

async function boot() {
  await initStorage({ native: isNative });
  initProfile();
  applySettings();
  on('settings', applySettings);
  on('profile-reset', applySettings);

  initBackground();
  initModals(document.getElementById('modal-root'), document.getElementById('toast-root'));
  initRouter(document.getElementById('screen-root'));
  [menuScreen, playScreen, campaignScreen, sectorScreen, dailyScreen, statsScreen, achievementsScreen, howtoScreen, settingsScreen]
    .forEach(registerScreen);

  on('achievements', (list) => {
    list.forEach((a, k) => setTimeout(() => { sfx.achievement(); toast(`${a.name} — ${a.desc}`, { kind: 'achievement', icon: a.icon, duration: 3600 }); }, k * 700));
  });
  on('sets-unlocked', (keys) => keys.forEach((k) => toast(`New symbol set: ${SYMBOL_SETS[k].name}`, { kind: 'success', icon: '🧩' })));

  await initPlatform({
    onBack: () => handleBack(),
    onPause: () => { emit('app-pause'); setAudioSuspended(true); },
    onResume: () => setAudioSuspended(false),
  });

  // Desktop/web: Escape acts like the back button.
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { handleBack(); e.preventDefault(); }
  });

  // Audio can only start after a user gesture.
  const unlock = () => unlockAudio();
  window.addEventListener('pointerdown', unlock, { capture: true });
  window.addEventListener('keydown', unlock, { capture: true });

  reset('menu');
  document.getElementById('boot-splash')?.classList.add('gone');
  setTimeout(() => document.getElementById('boot-splash')?.remove(), 600);
  hideSplash();

  // Ads (native only): consent first, after the menu is on screen.
  if (isNative) setTimeout(() => initAds(), 800);

  registerServiceWorker();
}

/** Offline support for the web/PWA build only. */
function registerServiceWorker() {
  if (isNative || isElectron || !('serviceWorker' in navigator)) return;
  if (!/^https?:$/.test(location.protocol)) return;
  if (import.meta.env.DEV || import.meta.env.VITE_NO_SW) return;
  import('virtual:pwa-register')
    .then(({ registerSW }) => registerSW({ immediate: true }))
    .catch(() => { /* not available in this build */ });
}

boot().catch((err) => {
  console.error(err);
  hideSplash();
  const el = document.getElementById('boot-splash');
  if (el) el.querySelector('.boot-text').textContent = 'Something went wrong starting the game. Please reload.';
});
