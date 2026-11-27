import { useEffect, useRef } from "react";
import { guardian } from "../safety";
import { showById, styleById } from "../data";

/** The Voyage console runs inside the app in a same-origin frame. It stays loaded while you browse other
 * tabs, so a show keeps playing (and never stops abruptly when you switch pages). FADE ALL reaches it. */
export function ConsoleFrame({ visible, query }: { visible: boolean; query: URLSearchParams }) {
  const ref = useRef<HTMLIFrameElement>(null);
  const style = query.get("style");
  const show = query.get("show");
  const hash = style && styleById.has(style) ? `#style=${style}` : show && showById.has(show) ? `#show=${show}` : "";

  // FADE ALL -> the console fades its audio to silence over 2 s
  useEffect(() => {
    guardian.onFadeAll(() => {
      ref.current?.contentWindow?.postMessage({ type: "clc:fade-all" }, location.origin);
    });
  }, []);

  // deep links: only the fragment changes, so the console doesn't reload; it picks the style or show and waits for Start
  useEffect(() => {
    const w = ref.current?.contentWindow;
    if (w && hash) {
      try {
        if (w.location.hash !== hash) w.location.hash = hash;
      } catch {
        /* not loaded yet: the initial src carries the hash */
      }
    }
  }, [hash]);

  return (
    <section className={`play ${visible ? "" : "hidden"}`} aria-label="Voyage console" aria-hidden={!visible}>
      <div className="play-bar">
        <span>
          Press <b>Start audio</b> inside and start low. Amplifier and exciters only, never a Tesla coil.
        </span>
      </div>
      <iframe
        ref={ref}
        className="console"
        title="Voyage console: tone engine and simulated light preview"
        src={`./console/index.html${hash}`}
        allow="fullscreen; autoplay"
        allowFullScreen
      />
    </section>
  );
}
