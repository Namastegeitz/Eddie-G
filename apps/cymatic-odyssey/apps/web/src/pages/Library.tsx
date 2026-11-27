import { useState } from "react";
import { href } from "../router";
import {
  fileUrl, media, mmss, modeHelp, modeLabel, showById, showNumber, shows, stepGuard, styleById, styleGuard, styles, videoName,
} from "../data";
import { GuardBadge, Icon, Label, PageHead, SimImg } from "../ui";

type Filter = "all" | "faraday" | "dipper" | "guarded";

export function StylesPage() {
  const [filter, setFilter] = useState<Filter>("all");
  const list = styles.filter((s) =>
    filter === "all" ? true : filter === "guarded" ? !styleGuard(s).ok : s.mode === filter,
  );
  const chips: Array<[Filter, string]> = [["all", "All 30"], ["faraday", "Whole dish"], ["dipper", "Dipper"], ["guarded", "Flicker-guarded"]];
  return (
    <div className="page">
      <PageHead kicker="Library" title="30 styles" sub="Each style is a printed gobo, a dish insert, a wave source and a signal. Tap one for its pictures, parts and settings." />
      <div className="chips" role="group" aria-label="Filter styles">
        {chips.map(([k, l]) => (
          <button key={k} className={`chip ${filter === k ? "on" : ""}`} aria-pressed={filter === k} onClick={() => setFilter(k)}>
            {l}
          </button>
        ))}
      </div>
      <div className="grid">
        {list.map((s) => (
          <a key={s.id} className="tcard" href={href(`styles/${s.id}`)}>
            <SimImg src={media(`styles/${s.id}-thumb.jpg`)} alt={s.name} />
            <span className="tcard-body">
              <span className="tcard-id">{s.id}</span>
              <b>{s.name}</b>
              <span className="tcard-mood">{s.mood}</span>
              <span className="tcard-meta">
                <span className="mchip">{modeLabel(s.mode)}</span>
                <GuardBadge g={styleGuard(s)} compact />
              </span>
            </span>
          </a>
        ))}
      </div>
    </div>
  );
}

export function StyleDetail({ id }: { id: string }) {
  const s = styleById.get(id);
  if (!s) return <NotFound what="style" back="styles" />;
  const i = styles.indexOf(s);
  const prev = styles[(i + styles.length - 1) % styles.length]!;
  const next = styles[(i + 1) % styles.length]!;
  const g = styleGuard(s);
  const fB = s.ratio ? (s.f * s.ratio[0]) / s.ratio[1] : null;
  const water = s.mode === "faraday" ? s.f / 2 : s.f;
  const inShows = shows.filter((sh) => sh.steps.some((st) => st.style === s.id));
  return (
    <div className="page detail">
      <PageHead back={{ href: href("styles"), label: "All styles" }} kicker={`${s.id} · ${s.mood}`} title={s.name} sub={s.how} />
      <div className="detail-grid">
        <div className="detail-media">
          <SimImg className="big" src={media(`styles/${s.id}-wall.jpg`)} alt={`${s.name} on the wall`} loading="eager" />
          <div className="pair">
            <SimImg src={media(`styles/${s.id}-water.jpg`)} alt={`${s.name}: water only, no gobo`} />
            <SimImg src={media(`styles/${s.id}-chamber.jpg`)} alt={`${s.name} in the compact chamber`} kind="3D RENDER" />
          </div>
        </div>
        <div className="detail-info">
          <a className="btn primary wide" href={href(`play?style=${s.id}`)}>
            <Icon name="play" size={18} /> Set it up in the console
          </a>
          <p className={`guard-note ${g.ok ? "ok" : "lim"}`}>{g.text}</p>
          <h2>Signal</h2>
          <table className="kv">
            <tbody>
              <tr><th>Drive</th><td>{modeLabel(s.mode)} <Label kind="Setting" /><small>{modeHelp(s.mode)}</small></td></tr>
              <tr><th>Frequency</th><td>{s.f} Hz <Label kind="Setting" /></td></tr>
              <tr><th>Second tone</th><td>{fB ? `${fB.toFixed(1)} Hz (${s.ratio![0]}:${s.ratio![1]})` : "none"} {fB && <Label kind="Setting" />}</td></tr>
              <tr><th>Water answers at</th><td>{water.toFixed(1)} Hz <Label kind="Estimated" /></td></tr>
              <tr><th>Pulse</th><td>{s.pulse ? `${s.pulse} per second` : "steady"}</td></tr>
              <tr><th>Breathe</th><td>{s.breathe ? `${s.breathe} Hz (${(s.breathe * 60).toFixed(0)} per minute)` : "off"}</td></tr>
              <tr><th>Palette</th><td><span className="pal">{s.pal.map((c) => <i key={c} style={{ background: c }} />)}</span></td></tr>
            </tbody>
          </table>
          <h2>Parts to print</h2>
          <table className="kv">
            <tbody>
              <tr><th>Gobo</th><td>{s.gobo}</td></tr>
              <tr><th>Dish insert</th><td>{s.insert}</td></tr>
              <tr><th>Wave source</th><td>{s.dipper ?? "Platform (whole dish)"}</td></tr>
              <tr><th>Best for</th><td>{s.best}</td></tr>
            </tbody>
          </table>
          <p className="files">
            Kit folder <code>{s.folder}</code> is inside{" "}
            <a href={fileUrl("CYMATIC_ODYSSEY_30_style_kits.zip")} target="_blank" rel="noopener">the 30 style kits (31 MB)</a>; Bambu Studio plates are in{" "}
            <a href={fileUrl("CYMATIC_ODYSSEY_Bambu_Studio.zip")} target="_blank" rel="noopener">the Bambu zip (24 MB)</a>.
          </p>
          {inShows.length > 0 && (
            <>
              <h2>Appears in</h2>
              <p className="links">
                {inShows.map((sh) => (
                  <a key={sh.id} className="chip" href={href(`shows/${sh.id}`)}>{sh.name}</a>
                ))}
              </p>
            </>
          )}
        </div>
      </div>
      <nav className="prevnext" aria-label="More styles">
        <a href={href(`styles/${prev.id}`)}><Icon name="back" size={16} /> {prev.id} {prev.name}</a>
        <a href={href(`styles/${next.id}`)}>{next.id} {next.name} <Icon name="arrow" size={16} /></a>
      </nav>
    </div>
  );
}

export function ShowsPage() {
  return (
    <div className="page">
      <PageHead kicker="Library" title="15 light shows" sub="Ten minutes each. The last minute of every show becomes the next one's opening, so all fifteen flow into one 150-minute journey." />
      <div className="grid shows">
        {shows.map((sh, i) => {
          const guarded = sh.steps.filter((st) => !stepGuard(st).ok).length;
          return (
            <a key={sh.id} className="scard" href={href(`shows/${sh.id}`)}>
              <SimImg src={media(`shows/${sh.id}.jpg`)} alt={`${sh.name} poster`} />
              <span className="scard-body">
                <span className="tcard-id">Show {i + 1} of {shows.length}</span>
                <b>{sh.name}</b>
                <span className="tcard-mood">{sh.mood}</span>
                <span className="tcard-meta">
                  <span className="mchip">{sh.minutes} min</span>
                  {guarded > 0 ? <span className="gbadge lim">{guarded} guarded step{guarded > 1 ? "s" : ""}</span> : <span className="gbadge ok">Plays as designed</span>}
                </span>
              </span>
            </a>
          );
        })}
      </div>
    </div>
  );
}

export function ShowDetail({ id }: { id: string }) {
  const sh = showById.get(id);
  if (!sh) return <NotFound what="show" back="shows" />;
  const next = showById.get(sh.next);
  const guest = showById.get(sh.guest_from);
  let t = 0;
  return (
    <div className="page detail">
      <PageHead back={{ href: href("shows"), label: "All shows" }} kicker={`Show ${showNumber(sh.id)} of ${shows.length} · ${sh.minutes} minutes`} title={sh.name} sub={sh.mood} />
      <div className="detail-grid">
        <div className="detail-media">
          <figure className="sim video">
            <video controls playsInline preload="none" poster={media(`shows/${sh.id}.jpg`)} src={fileUrl(`videos/${videoName(sh.id)}`)} />
            <figcaption className="sim-tag">SIMULATION</figcaption>
          </figure>
          <p className="fine">33-second preview with sound (streams from the web, about 7 MB).</p>
        </div>
        <div className="detail-info">
          <a className="btn primary wide" href={href(`play?show=${sh.id}`)}>
            <Icon name="play" size={18} /> Set it up in the console
          </a>
          <p className="fine">
            {guest && <>Guest style borrowed from <a href={href(`shows/${guest.id}`)}>{guest.name}</a>. </>}
            {next && <>Flows into <a href={href(`shows/${next.id}`)}>{next.name}</a>.</>} Dish insert: {sh.insert}.
          </p>
          <h2>Timeline</h2>
          <ol className="timeline">
            {sh.steps.map((st, i) => {
              const s = st.style ? styleById.get(st.style) : undefined;
              const g = stepGuard(st);
              const start = t;
              t += st.t;
              return (
                <li key={i}>
                  <span className="tl-time">{mmss(start)}</span>
                  {s ? <img src={media(`styles/${s.id}-thumb.jpg`)} alt="" loading="lazy" /> : <span className="tl-dot" />}
                  <span className="tl-body">
                    <b>{s ? <a href={href(`styles/${s.id}`)}>{s.name}</a> : `${st.mode} ${st.f} Hz`}</b>
                    <span className="tl-role">{st.role}</span>
                    <span className="tl-sig">
                      {modeLabel(st.mode)} {st.f} Hz{st.ratio ? ` + ${st.ratio[0]}:${st.ratio[1]}` : ""}{st.pulse ? `, pulse ${st.pulse}/s` : ""} · {mmss(st.t)}
                    </span>
                    {!g.ok && <span className="gbadge lim" title={g.text}>Guarded: beat {g.beatHz!.toFixed(0)} Hz</span>}
                  </span>
                </li>
              );
            })}
          </ol>
        </div>
      </div>
    </div>
  );
}

function NotFound({ what, back }: { what: string; back: string }) {
  return (
    <div className="page">
      <PageHead title={`No such ${what}`} back={{ href: href(back), label: "Back" }} />
    </div>
  );
}

