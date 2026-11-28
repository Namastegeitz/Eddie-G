import { useEffect, useState } from "react";

/** Tiny hash router: #/styles/S05?x=1 -> { path: ["styles", "S05"], query: {x: "1"} }. Hash routes work on
 * GitHub Pages, from a file, and inside the Capacitor apps without any server rewrites. */
export interface Route {
  path: string[];
  query: URLSearchParams;
}

export function parseHash(hash: string): Route {
  const raw = hash.replace(/^#\/?/, "");
  const [p = "", q = ""] = raw.split("?");
  return { path: p.split("/").filter(Boolean).map(decodeURIComponent), query: new URLSearchParams(q) };
}

export const href = (path: string) => `#/${path.replace(/^\//, "")}`;

export function useRoute(): Route {
  const [route, setRoute] = useState(() => parseHash(location.hash));
  useEffect(() => {
    const on = () => {
      setRoute(parseHash(location.hash));
      window.scrollTo({ top: 0 });
    };
    window.addEventListener("hashchange", on);
    return () => window.removeEventListener("hashchange", on);
  }, []);
  return route;
}
