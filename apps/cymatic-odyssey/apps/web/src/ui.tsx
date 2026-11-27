import type { ReactNode } from "react";
import type { GuardStatus } from "./data";

const PATHS: Record<string, string> = {
  home: "M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z",
  play: "M8 5.5v13a1 1 0 0 0 1.5.86l10.5-6.5a1 1 0 0 0 0-1.72L9.5 4.64A1 1 0 0 0 8 5.5z",
  styles: "M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z",
  shows: "M4 6h16M4 12h16M4 18h10M18 16l3 2-3 2z",
  build: "M14.7 6.3a4 4 0 0 0-5.2 5.2L3 18l3 3 6.5-6.5a4 4 0 0 0 5.2-5.2l-2.6 2.6-2.8-.4-.4-2.8z",
  safety: "M12 3 4 6v6c0 4.5 3.4 8.3 8 9 4.6-.7 8-4.5 8-9V6z",
  device: "M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2",
  share: "M12 3v12M7 8l5-5 5 5M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6",
  download: "M12 3v12M7 10l5 5 5-5M5 21h14",
  arrow: "M5 12h14M13 6l6 6-6 6",
  back: "M19 12H5M11 6l-6 6 6 6",
};

export function Icon({ name, size = 22 }: { name: keyof typeof PATHS | string; size?: number }) {
  const filled = name === "play" || name === "home" || name === "styles";
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true" focusable="false"
      fill={filled ? "currentColor" : "none"} stroke={filled ? "none" : "currentColor"} strokeWidth={1.9} strokeLinecap="round" strokeLinejoin="round">
      <path d={PATHS[name] ?? ""} />
    </svg>
  );
}

/** Every simulated picture is labelled; the label is also burned into the image file itself. */
export function SimImg({ src, alt, kind = "SIMULATION", className = "", loading = "lazy" }: { src: string; alt: string; kind?: "SIMULATION" | "3D RENDER"; className?: string; loading?: "lazy" | "eager" }) {
  return (
    <figure className={`sim ${className}`}>
      <img src={src} alt={`${alt} (${kind.toLowerCase()})`} loading={loading} decoding="async" />
      <figcaption className="sim-tag">{kind}</figcaption>
    </figure>
  );
}

export function GuardBadge({ g, compact = false }: { g: GuardStatus; compact?: boolean }) {
  return (
    <span className={`gbadge ${g.ok ? "ok" : "lim"}`} title={g.text}>
      {g.ok ? "Plays as designed" : compact ? "Guarded" : "Flicker guard: 2nd tone at 10 %"}
    </span>
  );
}

export function Label({ kind }: { kind: "Estimated" | "Simulated" | "Measured" | "Setting" | "Tradition (not science)" }) {
  return <span className={`lbl lbl-${kind.split(" ")[0]!.toLowerCase()}`}>{kind}</span>;
}

export function Card({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`card ${className}`}>{children}</div>;
}

export function PageHead({ kicker, title, sub, back }: { kicker?: string; title: string; sub?: ReactNode; back?: { href: string; label: string } }) {
  return (
    <header className="page-head">
      {back && (
        <a className="back" href={back.href}>
          <Icon name="back" size={18} /> {back.label}
        </a>
      )}
      {kicker && <p className="kicker">{kicker}</p>}
      <h1>{title}</h1>
      {sub && <p className="sub">{sub}</p>}
    </header>
  );
}
