import { useEffect, useMemo, useState } from "react";
import { getClaim } from "@clc/content";
import { legacySummary, legacyStyles } from "@clc/core-geometry";
import { detectCapabilities, deviceRole, type ProbeEnv } from "./capabilities";
import { guardian } from "./safety";

const MODES = [
  { id: "personal", name: "Personal Show", who: "You at home", what: "Show playlists, your own music through the water, sunset schedule, clips.", phase: "P1-P6" },
  { id: "studio", name: "Studio Session", who: "Yoga studios, sound-bath facilitators", what: "Tablet conductor, session arcs, live bowl follow.", phase: "P6-P7" },
  { id: "silent", name: "Silent Sound Bath", who: "Studio groups", what: "Each guest joins by QR code; personal headphone layers in sync with the room.", phase: "P7" },
  { id: "retail", name: "Retail Display", who: "Holistic and metaphysical stores", what: "Attract loop of real patterns, QR to shop, kiosk lock.", phase: "P7" },
  { id: "learn", name: "Learn / Lab", who: "Everyone, classrooms", what: "Dispersion, bowl modes, Chladni's law, the Symmetry Map, what the science says.", phase: "P2" },
  { id: "forge", name: "STL Forge", who: "Makers", what: "Geometry families to printable plates, lanterns and gobos with a light-throw preview.", phase: "P4" },
] as const;

const NOTICE_KEY = "clc-safety-notice-v1";

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
          <strong>Sound:</strong> start quietly. Headphone modes are not for use while driving or operating machinery.
        </p>
        <p>
          If you have epilepsy or light sensitivity, tinnitus or sound sensitivity, or you are under medical or mental-health care, check with your clinician first. These sessions are relaxation and art experiences, <strong>not therapy</strong>.
        </p>
        <button className="primary" onClick={onAccept}>I understand</button>
      </div>
    </div>
  );
}

export function App() {
  const [accepted, setAccepted] = useState<boolean>(() => {
    try {
      return localStorage.getItem(NOTICE_KEY) === "yes";
    } catch {
      return false;
    }
  });
  const [faded, setFaded] = useState<string | null>(null);
  const caps = useMemo(() => detectCapabilities(globalThis as unknown as ProbeEnv), []);
  const role = deviceRole(caps);
  const lib = legacySummary();

  useEffect(() => {
    guardian.onFadeAll((ms) => setFaded(`FADE ALL sent: every output fades to safe idle over ${ms / 1000} s.`));
  }, []);

  const accept = () => {
    try {
      localStorage.setItem(NOTICE_KEY, "yes");
    } catch {
      /* private mode: show the notice again next time */
    }
    setAccepted(true);
  };

  return (
    <div className="app">
      <header className="top">
        <div>
          <p className="kicker">Working name</p>
          <h1>Cymatic Light Chamber</h1>
          <p className="sub">See your sound. Art and relaxation experience, not a medical device.</p>
        </div>
      </header>

      <button className="fade-all" onClick={() => guardian.fadeAll()} aria-label="Fade all outputs to safe idle">
        FADE ALL
      </button>
      {faded && <p className="toast" role="status">{faded}</p>}

      <main>
        <section aria-labelledby="modes-h">
          <h2 id="modes-h">Modes</h2>
          <p className="muted">P0 scaffold: the modes below are planned, not built yet. Each card says which phase delivers it.</p>
          <div className="modes">
            {MODES.map((m) => (
              <article key={m.id} className="mode">
                <h3>{m.name}</h3>
                <p className="who">{m.who}</p>
                <p>{m.what}</p>
                <p className="phase">Arrives in {m.phase}</p>
              </article>
            ))}
          </div>
        </section>

        <section aria-labelledby="dev-h">
          <h2 id="dev-h">This device</h2>
          <p className={role.controller ? "ok" : "warn"}>{role.summary}</p>
          <table className="caps">
            <thead>
              <tr><th>Capability</th><th>Here</th><th>Note</th></tr>
            </thead>
            <tbody>
              {caps.map((c) => (
                <tr key={c.id}>
                  <td>{c.label}</td>
                  <td><span className={`pill ${c.status}`}>{c.status}</span></td>
                  <td>{c.note}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="muted">Detected at runtime by feature checks; never guessed from the browser name.</p>
        </section>

        <section aria-labelledby="lib-h">
          <h2 id="lib-h">Your existing library</h2>
          <p>
            The current generator (tools/, Python) keeps working: <strong>{lib.total}</strong> printable looks in {lib.families} families ({lib.gobo} gobos, {lib.insert} inserts, {lib.dipper} wave feet) and <strong>{lib.styles}</strong> styles. They move into the STL Forge in P4.
          </p>
          <ul className="styles">
            {legacyStyles.map((s) => (
              <li key={s.id}>
                <span className="sw" style={{ background: `linear-gradient(90deg, ${s.pal.join(",")})` }} aria-hidden="true" />
                <b>{s.id}</b> {s.name} <span className="muted">· {s.mode === "faraday" ? "whole-dish drive" : "dipper"} {s.f} Hz</span>
              </li>
            ))}
          </ul>
        </section>
      </main>

      <footer className="foot">
        <p>Every simulated image is marked SIMULATION. Every number is labelled Measured, Simulated, Estimated or Tradition (not science). See TRANSPARENCY.md.</p>
      </footer>

      {!accepted && <SafetyNotice onAccept={accept} />}
    </div>
  );
}
