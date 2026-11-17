import { defineConfig } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';
import { readFileSync } from 'node:fs';

const pkg = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'));

export default defineConfig({
  // Relative base so the same build runs from a web host, a sub-folder,
  // Capacitor's webview and Electron's file:// loader.
  base: './',
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
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
