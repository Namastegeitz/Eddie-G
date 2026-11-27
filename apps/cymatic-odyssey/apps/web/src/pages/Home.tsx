import { href } from "../router";
import { media, shows, styles, styleGuard } from "../data";
import { Icon, SimImg } from "../ui";

const FEATURED = ["S05", "S03", "S12", "S17", "S25", "S30"];

export function Home() {
  const guarded = styles.filter((s) => !styleGuard(s).ok).length;
  return (
    <div className="page home">
      <section className="hero">
        <div className="hero-copy">
          <p className="kicker">Cymatic Light Chamber</p>
          <h1>
            Sound shapes water.
            <br />
            <span className="grad">Water shapes light.</span>
          </h1>
          <p className="lede">
            A shallow dish of water, a speaker and a lamp. Tones make standing waves on the water, and the rippling surface bends the light into geometric patterns on your wall.
          </p>
          <div className="cta">
            <a className="btn primary" href={href("play")}>
              <Icon name="play" size={18} /> Open the console
            </a>
            <a className="btn" href={href("styles")}>
              Browse 30 styles
            </a>
          </div>
          <p className="fine">The console plays real tones through your speaker. The pictures here are simulations of what the chamber projects.</p>
        </div>
        <div className="hero-art">
          <SimImg className="round" src={media("styles/S05-wall.jpg")} alt="Metatron style on a wall" loading="eager" />
        </div>
      </section>

      <section className="how" aria-labelledby="how-h">
        <h2 id="how-h">How it works</h2>
        <ol className="steps3">
          <li>
            <b>Sound</b>
            <span>An exciter shakes the dish, or a printed foot taps the surface, at 8-200 Hz.</span>
          </li>
          <li>
            <b>Water</b>
            <span>A 5 mm layer of water forms standing waves: hexagons, squares, rings, quasicrystals.</span>
          </li>
          <li>
            <b>Light</b>
            <span>Light through the ripples focuses into bright lines (caustics). A printed gobo adds geometry.</span>
          </li>
        </ol>
      </section>

      <section aria-labelledby="feat-h">
        <div className="row-head">
          <h2 id="feat-h">Featured styles</h2>
          <a href={href("styles")} className="more">
            All 30 <Icon name="arrow" size={16} />
          </a>
        </div>
        <div className="rail">
          {FEATURED.map((id) => {
            const s = styles.find((x) => x.id === id)!;
            return (
              <a key={id} className="rail-item" href={href(`styles/${id}`)}>
                <SimImg className="round" src={media(`styles/${id}-thumb.jpg`)} alt={s.name} />
                <span className="rail-name">{s.name}</span>
                <span className="rail-mood">{s.mood}</span>
              </a>
            );
          })}
        </div>
      </section>

      <section className="tiles" aria-label="Sections">
        <a className="tile" href={href("shows")}>
          <span className="tile-n">{shows.length}</span>
          <b>Light shows</b>
          <span>Ten minutes each, chained into one 150-minute journey.</span>
        </a>
        <a className="tile" href={href("build")}>
          <span className="tile-n">77</span>
          <b>Page build manual</b>
          <span>Five models, parts, Bambu printing, 7 illustrated steps, downloads.</span>
        </a>
        <a className="tile" href={href("safety")}>
          <span className="tile-n">
            <Icon name="safety" size={28} />
          </span>
          <b>Safety and science</b>
          <span>What it is, what it isn't, the flicker guard, where every claim comes from.</span>
        </a>
        <a className="tile" href={href("device")}>
          <span className="tile-n">
            <Icon name="share" size={28} />
          </span>
          <b>Install and share</b>
          <span>Put it on your home screen, or send it to another phone or tablet.</span>
        </a>
      </section>

      <section className="honest" aria-labelledby="honest-h">
        <h2 id="honest-h">What's real today</h2>
        <ul>
          <li>
            <b>Real:</b> the console's tone engine (it drives your amplifier and exciters), the 30 printable style kits and the build manual.
          </li>
          <li>
            <b>Simulated:</b> every pattern picture and video in this app, computed from a physics model and marked SIMULATION.
          </li>
          <li>
            <b>Not measured yet:</b> no chamber has been built and filmed, so frequencies and looks are estimates until you map your own dish.
          </li>
          <li>
            <b>Flicker guard:</b> {guarded} of the 30 styles use two tones that would beat in the 3-60 Hz band; the app turns their second tone down automatically.
          </li>
        </ul>
      </section>
    </div>
  );
}
