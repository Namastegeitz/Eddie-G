import { useMemo, useState } from "react";
import { getClaim } from "@clc/content";
import { AUDIO, LIGHT } from "@clc/core-safety";
import { detectCapabilities, deviceRole, type ProbeEnv } from "../capabilities";
import { ANDROID_APK, APP_VERSION, fileUrl, GOBO_FAMILIES, isNative, MAIN_DOWNLOADS, SITE_URL, shows, styleGuard, styles, videoName } from "../data";
import { href } from "../router";
import { Icon, PageHead } from "../ui";

export function BuildPage() {
  const lib = __LIBRARY__;
  return (
    <div className="page">
      <PageHead kicker="Build it" title="Manual and downloads" sub="Everything to build a chamber and print its parts. Files open from the web, so you need a connection for these." />
      <a className="feature" href={fileUrl("CYMATIC_ODYSSEY_Manual.pdf")} target="_blank" rel="noopener">
        <span className="feature-n">77</span>
        <span>
          <b>The complete manual (PDF)</b>
          <span>How it works, safety, five models, parts and tools, Bambu printing, 7 illustrated assembly steps, wiring, first light, every style and show. 19 MB.</span>
        </span>
        <Icon name="download" />
      </a>
      <h2>Five ways to build</h2>
      <div className="models">
        {[
          ["C", "Shadow Caster", "$0-30", "A flashlight through a jar or dish onto a wall. Start tonight."],
          ["E", "Desk Dipper", "$40-60", "Small dish, 3-inch speaker and a dipper arm. Ceiling projection."],
          ["A", "Compact Chamber", "about $300-450", "LED below, lens and mirror above. The flagship build in the manual."],
          ["B", "Overhead Projector", "about $150 + projector", "Dish on a used overhead projector. Brightest, simplest optics."],
          ["D", "Venue Pro", "about $500-800", "300 mm dish, ceiling or dome projection, sealed electronics."],
        ].map(([k, n, c, d]) => (
          <div key={k} className="model">
            <span className="model-k">{k}</span>
            <b>{n}</b>
            <span className="model-c">{c} <small>(estimate)</small></span>
            <span>{d}</span>
          </div>
        ))}
      </div>
      <h2>Downloads</h2>
      <ul className="dl">
        {MAIN_DOWNLOADS.map((d) => (
          <li key={d.file}>
            <a href={fileUrl(d.file)} target="_blank" rel="noopener">
              <span>
                <b>{d.title}</b>
                <span>{d.what}</span>
              </span>
              <span className="dl-size">{d.size}</span>
            </a>
          </li>
        ))}
      </ul>
      <details className="more-dl">
        <summary>Gobo families: all {lib.gobo} printable gobos in {GOBO_FAMILIES.length} zips</summary>
        <p className="links">
          {GOBO_FAMILIES.map((f) => (
            <a key={f} className="chip" href={fileUrl(`gobos_${f}.zip`)} target="_blank" rel="noopener">{f}</a>
          ))}
        </p>
      </details>
      <details className="more-dl">
        <summary>Show videos: 15 previews (33 s, vertical, about 7 MB each, simulated)</summary>
        <p className="links">
          {shows.map((s, i) => (
            <a key={s.id} className="chip" href={fileUrl(`videos/${videoName(s.id)}`)} target="_blank" rel="noopener">{i + 1}. {s.name}</a>
          ))}
        </p>
      </details>
      <h2>Everything in one folder on your computer</h2>
      <p>Makes a <b>Cymatic Light Chamber</b> folder on your Desktop with the manual, all print files, the gobo library, the show videos and the Android app (about 280 MB). Paste one line and press Enter; run it again later to fetch only what's new.</p>
      <div className="cmd">
        <b>Mac (Terminal)</b>
        <code>curl -fsSL {fileUrl("get-desktop-folder.sh")} | bash</code>
      </div>
      <div className="cmd">
        <b>Windows (PowerShell)</b>
        <code>irm {fileUrl("get-desktop-folder.ps1")} | iex</code>
      </div>
      <p className="fine">
        The source files, docs and generators are on GitHub: <a href="https://github.com/Namastegeitz/Eddie-G/tree/claude/peaceful-babbage-k8oen2/apps/cymatic-odyssey" target="_blank" rel="noopener">Namastegeitz/Eddie-G</a>.
      </p>
    </div>
  );
}

export function SafetyPage() {
  const flk = getClaim("C-FLK-01");
  const guarded = styles.filter((s) => !styleGuard(s).ok).length;
  return (
    <div className="page prose">
      <PageHead kicker="Safety and science" title="What it is, and what it isn't" />
      <div className="callout">
        <b>An art and relaxation experience.</b> It is not therapy and not a medical device. It doesn't diagnose or prevent anything, and we attach no health benefits to any frequency.
      </div>
      <h2>Light and flicker</h2>
      <p>
        {flk?.whatWeSay} <span className="claim">({flk?.id}, evidence grade {flk?.grade})</span>
      </p>
      <ul>
        <li>There is no strobe mode, by design.</li>
        <li>Lights change at most {LIGHT.maxTransitionsPerWindow} times a second (1.5 flashes), with fades of at least {LIGHT.minFadeMs / 1000} s.</li>
        <li>Two drive tones that differ by 3-60 Hz make the light on the wall flicker at that rate. The app turns the second tone down to 10 % ({guarded} of the 30 styles are affected). Full strength only in Lab mode, alone, never in a public space.</li>
        <li>Pulses are capped at 3 per second.</li>
      </ul>
      <h2>Sound</h2>
      <ul>
        <li>Volume starts at {AUDIO.masterDefaultDbfs} dBFS, fades in over at least {AUDIO.minFadeInS} s and out over at least {AUDIO.minFadeOutS} s, and never goes above {AUDIO.hardCeilingDbfs} dBFS.</li>
        <li>FADE ALL (top right) fades everything to silence in 2 seconds.</li>
      </ul>
      <h2>Water, power and the Tesla coil</h2>
      <ul>
        <li>24 V DC only inside the chamber, from a listed adapter on a GFCI outlet. Electronics beside or above the water, never under it.</li>
        <li>The EZ-100 Tesla coil can't shake water. Keep it at least 50 cm away from the chamber, dry and ventilated. Never connect it to this app's audio.</li>
        <li>Distilled water with a drop of dish soap. Never mercury or other toxic liquids.</li>
      </ul>
      <h2>Labels you'll see</h2>
      <ul>
        <li><b>SIMULATION</b>: computed from a physics model. Every pattern picture and video here is one.</li>
        <li><b>3D RENDER</b>: a Blender picture of the printed parts.</li>
        <li><b>Estimated</b>: a calculation with stated assumptions. <b>Setting</b>: a value you choose.</li>
        <li><b>Measured</b>: from a sensor on your own chamber (coming with the camera features).</li>
      </ul>
      <p className="fine">
        If you have epilepsy or light sensitivity, tinnitus or sound sensitivity, or you're under medical or mental-health care, check with your clinician first. Sources and evidence grades: TRANSPARENCY.md in the project.
      </p>
      <p className="links">
        <a className="chip" href="./privacy/">Privacy policy</a>
        <a className="chip" href="./support/">Support</a>
      </p>
    </div>
  );
}

export function DevicePage() {
  const caps = useMemo(() => detectCapabilities(globalThis as unknown as ProbeEnv), []);
  const role = deviceRole(caps);
  const [msg, setMsg] = useState("");
  const native = isNative();
  const share = async () => {
    const data = { title: "Cymatic Light Chamber", text: "Sound shapes water, water shapes light: 30 styles and 15 light shows.", url: SITE_URL };
    try {
      if (navigator.share) {
        await navigator.share(data);
        return;
      }
      await navigator.clipboard.writeText(SITE_URL);
      setMsg("Link copied.");
    } catch {
      setMsg(SITE_URL);
    }
  };
  return (
    <div className="page prose">
      <PageHead kicker="Install and share" title="On every phone and tablet" />
      <div className="share-box">
        <p>
          <b>Link for any phone, tablet or computer:</b>
          <br />
          <a href={SITE_URL} className="url">{SITE_URL}</a>
        </p>
        <button className="btn primary" onClick={share}>
          <Icon name="share" size={18} /> Share the link
        </button>
        {msg && <p role="status" className="fine">{msg}</p>}
      </div>
      {!native && (
        <>
          <h2>Put it on your home screen</h2>
          <ul>
            <li><b>iPhone or iPad:</b> open the link in Safari, tap Share, then <b>Add to Home Screen</b>.</li>
            <li><b>Android:</b> open the link in Chrome, tap the menu, then <b>Install app</b> (or Add to Home screen).</li>
            <li><b>Computer:</b> in Chrome or Edge, click the install icon in the address bar.</li>
          </ul>
          <p>Once installed it opens full screen and works offline (the manual, zips and videos still need a connection).</p>
          <h2>Android app</h2>
          <p>
            Until it's on Google Play you can install the Android app directly: <a href={fileUrl(ANDROID_APK)}>download the APK</a>, open it, and allow your browser to install apps when Android asks.
          </p>
        </>
      )}
      <h2>This device</h2>
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
      <p className="fine">Checked on this device by feature tests, never guessed from the browser name. Version {APP_VERSION}.</p>
      <p className="links">
        <a className="chip" href="./privacy/">Privacy policy</a>
        <a className="chip" href="./support/">Support</a>
        <a className="chip" href={href("safety")}>Safety</a>
      </p>
    </div>
  );
}
