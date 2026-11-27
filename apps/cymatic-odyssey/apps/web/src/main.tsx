import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { isNative } from "./data";
import "./styles.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

// Offline support on the web. The native apps already carry every file, so they skip the service worker.
if (import.meta.env.PROD && !isNative() && "serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js", { scope: "./" }).catch(() => {
      /* offline support unavailable; the app still works online */
    });
  });
}
