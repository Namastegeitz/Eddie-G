import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig, type Plugin } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

const CONSOLE = fileURLToPath(new URL("../../console/index.html", import.meta.url));
// counts from the Python generator's catalog, baked in at build time (the 250 KB catalog itself stays out of the app)
const CATALOG = JSON.parse(readFileSync(fileURLToPath(new URL("../../catalog/geometry_catalog.json", import.meta.url)), "utf8")) as Array<{ part: string; family: string }>;
const LIBRARY = {
  total: CATALOG.length,
  gobo: CATALOG.filter((e) => e.part === "gobo").length,
  families: new Set(CATALOG.map((e) => e.family)).size,
};

/** Ships the single-file Voyage console (with its injected Safety Guardian) as ./console/index.html. */
function legacyConsole(): Plugin {
  return {
    name: "clc-legacy-console",
    configureServer(server) {
      server.middlewares.use("/console/index.html", (_req, res) => {
        res.setHeader("content-type", "text/html; charset=utf-8");
        res.end(readFileSync(CONSOLE));
      });
    },
    generateBundle() {
      this.emitFile({ type: "asset", fileName: "console/index.html", source: readFileSync(CONSOLE, "utf8") });
    },
  };
}

export default defineConfig({
  // relative paths: the same build runs on GitHub Pages (/Eddie-G/cymatic-light-chamber/) and inside the Capacitor apps
  base: "./",
  define: { __LIBRARY__: JSON.stringify(LIBRARY) },
  plugins: [
    react(),
    legacyConsole(),
    VitePWA({
      registerType: "autoUpdate",
      injectRegister: null, // registered in main.tsx, and skipped inside the native apps
      includeAssets: ["favicon-32.png", "apple-touch-icon.png", "og-card.jpg"],
      manifest: {
        id: "./",
        name: "Cymatic Light Chamber",
        short_name: "Light Chamber",
        description: "Sound shapes water, water shapes light: 30 styles, 15 light shows and a build manual. An art and relaxation experience, not a medical device.",
        theme_color: "#06071a",
        background_color: "#06071a",
        display: "standalone",
        orientation: "any",
        start_url: "./",
        scope: "./",
        categories: ["music", "entertainment", "lifestyle"],
        icons: [
          { src: "icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png" },
          { src: "icon-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
        ],
      },
      workbox: {
        globPatterns: ["**/*.{js,css,html,png,svg,webmanifest}", "media/styles/*-thumb.jpg"],
        maximumFileSizeToCacheInBytes: 3 * 1024 * 1024,
        // never answer a file download (PDF, zip, APK, video) with the app page
        navigateFallback: null,
        skipWaiting: true,
        clientsClaim: true,
        runtimeCaching: [
          {
            urlPattern: ({ url }) => url.pathname.includes("/media/"),
            handler: "CacheFirst",
            options: { cacheName: "clc-media", expiration: { maxEntries: 200 } },
          },
        ],
      },
    }),
  ],
  server: { fs: { allow: ["../.."] } },
});
