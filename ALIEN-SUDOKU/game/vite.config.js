import { defineConfig } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const pkg = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'));
// Firebase (Crashlytics, Remote Config) runs only when its config files are in the native
// projects. Add both together: android/app/google-services.json and ios/App/App/GoogleService-Info.plist.
const here = (p) => fileURLToPath(new URL(p, import.meta.url));
const HAS_FIREBASE = process.env.VITE_FIREBASE === '1'
  || existsSync(here('./android/app/google-services.json'))
  || existsSync(here('./ios/App/App/GoogleService-Info.plist'));
const firebaseWebStub = here('./src/platform/firebase-web-stub.js');

export default defineConfig({
  // Relative base so the same build runs from a web host, a sub-folder,
  // Capacitor's webview and Electron's file:// loader.
  base: './',
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
    __FIREBASE__: JSON.stringify(HAS_FIREBASE),
  },
  resolve: {
    // The Firebase plugins' web versions are never used (Firebase runs on iOS/Android only).
    alias: [{ find: /^firebase\/.*$/, replacement: firebaseWebStub }],
  },
  build: {
    target: ['es2020', 'safari15', 'chrome90'],
    assetsInlineLimit: 0,
    chunkSizeWarningLimit: 800,
    // SINGLE_FILE=1 (tools/package-artifact.mjs): one JS bundle, no lazy chunks.
    rollupOptions: process.env.SINGLE_FILE ? { output: { inlineDynamicImports: true } } : {},
  },
  server: { host: true, port: 5173 },
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      injectRegister: false, // registered from src/main.js on the web build only
      includeAssets: ['favicon.svg', 'icons/*.png', 'space/*.webp', 'opengraph.jpg'],
      manifest: {
        id: './',
        name: 'Alien Sudoku',
        short_name: 'Alien Sudoku',
        description: 'Decode the hieroglyphs of the lost UFO archive. Sudoku with alien glyphs, a campaign, daily puzzles and space music.',
        start_url: './',
        scope: './',
        display: 'standalone',
        orientation: 'any',
        background_color: '#05010f',
        theme_color: '#05010f',
        categories: ['games', 'puzzle'],
        icons: [
          { src: 'icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,webp,jpg,woff,woff2,json}'],
        maximumFileSizeToCacheInBytes: 4 * 1024 * 1024,
        navigateFallback: 'index.html',
      },
    }),
  ],
  test: {
    include: ['tests/**/*.test.js'],
    environment: 'node',
  },
});
