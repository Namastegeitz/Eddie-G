import { useEffect, useState, type ReactNode } from "react";
import { getClaim } from "@clc/content";
import { guardian } from "./safety";
import { href, useRoute } from "./router";
import { Icon } from "./ui";
import { Home } from "./pages/Home";
import { ShowDetail, ShowsPage, StyleDetail, StylesPage } from "./pages/Library";
import { ConsoleFrame } from "./pages/Play";
import { BuildPage, DevicePage, SafetyPage } from "./pages/Info";

const NOTICE_KEY = "clc-safety-notice-v1";
const TABS = [
  { id: "", label: "Home", icon: "home" },
  { id: "play", label: "Play", icon: "play" },
  { id: "styles", label: "Styles", icon: "styles" },
  { id: "shows", label: "Shows", icon: "shows" },
  { id: "build", label: "Build", icon: "build" },
] as const;

function SafetyNotice({ onAccept }: { onAccept: () => void }) {
  const flk = getClaim("C-FLK-01");
  return (
    <div className="notice" role="dialog" aria-modal="true" aria-labelledby="notice-title">
      <div className="notice-card">
        <h2 id="notice-title">Before you start</h2>
        <p>
          <strong>Light:</strong> {flk?.whatWeSay} Flashing between about 3 and 60 times a second is blocked by design, and there is no strobe mode.{" "}
          <span className="claim">({flk?.id}, grade {flk?.grade})</span>
        </p>
        <p>
          <strong>Sound:</strong> start quietly. The console drives an amplifier and exciters; never connect it to a Tesla coil.
        </p>
        <p>
          If you have epilepsy or light sensitivity, tinnitus or sound sensitivity, or you are under medical or mental-health care, check with your clinician first. This is an art and relaxation experience, <strong>not therapy</strong> and not a medical device.
        </p>
        <button className="btn primary" onClick={onAccept}>I understand</button>
      </div>
    </div>
  );
}

export function App() {
  const route = useRoute();
  const [accepted, setAccepted] = useState<boolean>(() => {
    try {
      return localStorage.getItem(NOTICE_KEY) === "yes";
    } catch {
      return false;
    }
  });
  const [toast, setToast] = useState<string | null>(null);
  const top = route.path[0] ?? "";
  const onPlay = top === "play";
  const [consoleOpened, setConsoleOpened] = useState(onPlay);
  useEffect(() => {
    if (onPlay) setConsoleOpened(true);
  }, [onPlay]);

  useEffect(() => {
    guardian.onFadeAll((ms) => {
      setToast(`FADE ALL: sound fades to silence over ${ms / 1000} s.`);
      window.setTimeout(() => setToast(null), 5000);
    });
  }, []);

  const accept = () => {
    try {
      localStorage.setItem(NOTICE_KEY, "yes");
    } catch {
      /* private mode: show the notice again next time */
    }
    setAccepted(true);
  };

  let page: ReactNode = null;
  if (top === "" || top === "home") page = <Home />;
  else if (top === "styles") page = route.path[1] ? <StyleDetail id={route.path[1]} /> : <StylesPage />;
  else if (top === "shows") page = route.path[1] ? <ShowDetail id={route.path[1]} /> : <ShowsPage />;
  else if (top === "build") page = <BuildPage />;
  else if (top === "safety") page = <SafetyPage />;
  else if (top === "device") page = <DevicePage />;
  else if (!onPlay) page = <Home />;

  return (
    <div className={`app ${onPlay ? "on-play" : ""}`}>
      <header className="bar">
        <a className="brand" href={href("")} aria-label="Cymatic Light Chamber, home">
          <img src="./icon-192.png" alt="" width={30} height={30} />
          <span>Light Chamber</span>
        </a>
        <nav className="topnav" aria-label="Main">
          {TABS.map((t) => (
            <a key={t.id} href={href(t.id)} aria-current={top === t.id || (t.id === "" && top === "home") ? "page" : undefined}>
              {t.label}
            </a>
          ))}
          <a href={href("safety")} aria-current={top === "safety" ? "page" : undefined}>Safety</a>
          <a href={href("device")} aria-current={top === "device" ? "page" : undefined}>Share</a>
        </nav>
        <button className="fade-all" onClick={() => guardian.fadeAll()} aria-label="FADE ALL: fade every sound and light to silence and dark">
          FADE ALL
        </button>
      </header>

      <main id="main">{page}</main>
      {consoleOpened && <ConsoleFrame visible={onPlay} query={route.query} />}

      {!onPlay && (
        <footer className="foot">
          <p>
            Every pattern picture is a SIMULATION until a real chamber is filmed. An art and relaxation experience, not a medical device.{" "}
            <a href={href("safety")}>Safety</a> · <a href="./privacy/">Privacy</a> · <a href="./support/">Support</a>
          </p>
        </footer>
      )}

      <nav className="tabs" aria-label="Main">
        {TABS.map((t) => (
          <a key={t.id} href={href(t.id)} aria-current={top === t.id || (t.id === "" && top === "home") ? "page" : undefined}>
            <Icon name={t.icon} />
            <span>{t.label}</span>
          </a>
        ))}
      </nav>

      {toast && <p className="toast" role="status">{toast}</p>}
      {!accepted && <SafetyNotice onAccept={accept} />}
    </div>
  );
}
