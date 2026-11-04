// Payments. Three modes:
//   'native' - inside the iPhone/Android app: Apple App Store or Google Play
//              billing through cordova-plugin-purchase (window.CdvPurchase).
//   'test'   - pretend purchases for trying the Shop: add ?billing=test to the
//              address or open it with #store-test. No money moves. Clearly labelled.
//   'none'   - a normal web browser: the Shop shows what exists and says
//              purchases are in the apps.
// The game never sees card details: the stores handle payment and only
// tell the game "this product was bought".
import { PRODUCTS, PRODUCT_PREFIX, getProduct } from './store.js';

export class Billing {
  constructor() {
    this.mode = 'none';
    this.platform = 'web';
    this.ready = false;
    this.info = new Map(); // id -> { price, micros, currency, canBuy }
    this.onDeliver = () => {};
    this.onChange = () => {};
    this.onError = () => {};
    this.testCounter = 0;
  }

  get canBuy() {
    return this.mode === 'native' || this.mode === 'test';
  }

  /** deliver(product, transactionId, priceInfo) must be idempotent per transaction. */
  async init({ onDeliver, onChange, onError } = {}) {
    if (onDeliver) this.onDeliver = onDeliver;
    if (onChange) this.onChange = onChange;
    if (onError) this.onError = onError;
    const C = window.Capacitor;
    const native = C && typeof C.getPlatform === 'function' && C.getPlatform() !== 'web';
    const testFlag = /[?&]billing=test\b/.test(location.search) || location.hash === '#store-test';
    if (native) {
      this.platform = C.getPlatform();
      // the purchase plugin's script loads with the app's cordova.js; wait for it
      const ok = await waitFor(() => window.CdvPurchase && window.CdvPurchase.store, 6000);
      if (ok) {
        this.mode = 'native';
        try {
          await this.initNative();
        } catch (e) {
          this.onError(`The ${this.storeName()} isn't available right now (${e && e.message ? e.message : e}). You can still play everything.`);
        }
        return;
      }
    }
    if (testFlag) {
      this.mode = 'test';
      for (const p of PRODUCTS) this.info.set(p.id, { price: `$${p.usd.toFixed(2)}`, micros: Math.round(p.usd * 1e6), currency: 'USD', canBuy: true });
      this.ready = true;
      this.onChange();
      return;
    }
    this.mode = 'none';
    for (const p of PRODUCTS) this.info.set(p.id, { price: `$${p.usd.toFixed(2)}`, micros: Math.round(p.usd * 1e6), currency: 'USD', canBuy: false });
    this.ready = true;
  }

  storeName() {
    return this.platform === 'ios' ? 'App Store' : this.platform === 'android' ? 'Google Play Store' : 'store';
  }

  async initNative() {
    const { store, ProductType, Platform, LogLevel } = window.CdvPurchase;
    const platform = this.platform === 'ios' ? Platform.APPLE_APPSTORE : Platform.GOOGLE_PLAY;
    this.cdvPlatform = platform;
    store.verbosity = LogLevel.WARNING;
    store.register(PRODUCTS.map((p) => ({
      id: PRODUCT_PREFIX + p.id,
      type: p.type === 'consumable' ? ProductType.CONSUMABLE : ProductType.NON_CONSUMABLE,
      platform,
    })));
    store.when()
      .productUpdated(() => this.refreshNative())
      .approved((transaction) => {
        // Grant, then finish so the store knows the item was delivered.
        for (const tp of transaction.products || []) {
          const id = String(tp.id || '').replace(PRODUCT_PREFIX, '');
          const p = getProduct(id);
          if (p) this.onDeliver(p, transaction.transactionId || `${id}-${Date.now()}`, this.info.get(id) || null);
        }
        transaction.finish();
      });
    store.error((err) => {
      if (err && err.code === window.CdvPurchase.ErrorCode.PAYMENT_CANCELLED) return;
      this.onError(err && err.message ? err.message : 'The purchase did not go through.');
    });
    await store.initialize([platform]);
    this.refreshNative();
    this.ready = true;
  }

  refreshNative() {
    const { store } = window.CdvPurchase;
    for (const p of PRODUCTS) {
      const prod = store.get(PRODUCT_PREFIX + p.id, this.cdvPlatform);
      const pricing = prod && prod.pricing;
      this.info.set(p.id, {
        price: pricing ? pricing.price : `$${p.usd.toFixed(2)}`,
        micros: pricing ? pricing.priceMicros : Math.round(p.usd * 1e6),
        currency: pricing ? pricing.currency : 'USD',
        canBuy: !!(prod && prod.canPurchase),
        owned: !!(prod && prod.owned),
        found: !!prod,
      });
    }
    this.onChange();
  }

  priceOf(id) {
    return this.info.get(id) || null;
  }

  /** Start a purchase. Resolves { ok, cancelled, error }. Delivery happens via onDeliver. */
  async buy(id) {
    const p = getProduct(id);
    if (!p) return { ok: false, error: 'Unknown product.' };
    if (this.mode === 'test') {
      await new Promise((r) => setTimeout(r, 250));
      this.onDeliver(p, `test-${Date.now()}-${++this.testCounter}`, this.info.get(id));
      return { ok: true };
    }
    if (this.mode !== 'native') return { ok: false, error: 'Purchases are available in the iPhone and Android apps.' };
    const { store, ErrorCode } = window.CdvPurchase;
    const prod = store.get(PRODUCT_PREFIX + id, this.cdvPlatform);
    const offer = prod && prod.getOffer();
    if (!offer) return { ok: false, error: `This item isn't available in the ${this.storeName()} yet.` };
    const err = await offer.order();
    if (err) {
      if (err.code === ErrorCode.PAYMENT_CANCELLED) return { ok: false, cancelled: true };
      return { ok: false, error: err.message || 'The purchase did not go through.' };
    }
    return { ok: true, pending: true };
  }

  /** Ask the store to re-send items bought before (new phone, reinstall). */
  async restore() {
    if (this.mode === 'native') {
      await window.CdvPurchase.store.restorePurchases();
      return { ok: true };
    }
    if (this.mode === 'test') return { ok: true, test: true };
    return { ok: false, error: 'Restoring purchases works in the iPhone and Android apps.' };
  }
}

function waitFor(test, ms) {
  return new Promise((resolve) => {
    const t0 = Date.now();
    const tick = () => {
      if (test()) return resolve(true);
      if (Date.now() - t0 > ms) return resolve(false);
      setTimeout(tick, 100);
    };
    tick();
  });
}
