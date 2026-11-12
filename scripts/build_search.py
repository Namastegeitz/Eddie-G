#!/usr/bin/env python3
"""Build the offline search index: assets/data/search-index.json

Run from anywhere:  python3 scripts/build_search.py
Re-run it after changing any guide page (and then scripts/build_sw.py, so
installed copies precache the new index).

What it does
------------
* Auto-discovers every guide page: APP/<folder>/index.html, except app-style
  pages that have no static guide text (map/) and the search page itself.
  New pages (e.g. plan/) are picked up automatically.
* Parses each page with Python's stdlib html.parser (no third-party deps) into
  a small tree, then walks it in document order and cuts it into entries:
    - one entry per <h2> section     (its own text, up to the first sub-entry)
    - one entry per <h3> subsection  (outside <details>)
    - one entry per <details> card   (heading = <summary> text; headings inside
                                      a card stay part of that card)
    - one "overview" entry for text before the first heading (lead, warnings)
* Adds a few hand-written entries for the map app's features (offline maps,
  SOS beacon, QR share, ...), which are UI rather than guide text.
* Validates every anchor: the id must exist in its page, and the optional
  "find" text (see below) must resolve to the entry's own heading. Any
  failure aborts the build with a non-zero exit code.

Entry format (keys kept short; the file is compact JSON with no indentation)
  p   page path relative to the app root, e.g. "water/index.html"
  pt  page title, e.g. "Water"
  h   section heading (h2 / h3 / summary text)
  a   anchor id to jump to: the heading's or <details>' own id, else the
      nearest ancestor id (usually the enclosing <section id>). "" = page top.
  t   plain text of the section, whitespace-collapsed, capped at TEXT_CAP chars
  c   (optional) parent heading path, e.g. "Severe bleeding" for a sub-section
  s   (optional) sub-line of a <details> card (its <summary> .sub span)
  f   (optional) exact heading text to scroll to inside the anchor element,
      used when the heading has no id of its own (common.js resolves it)
  k   (optional) extra keywords (hand-written entries)
  x   (optional) distinct words from the part of the text cut off by the cap,
      so long sections stay fully searchable without bloating the file
"""
import json
import os
import re
import sys
from html.parser import HTMLParser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'data', 'search-index.json')

# Folders that are not guide pages. map/ is an app (described by HAND_ENTRIES
# below); search/ is the search page itself.
SKIP_DIRS = {'map', 'search', 'assets', 'scripts', 'tests', 'dist', 'node_modules'}
TEXT_CAP = 1500
TITLE_SUFFIX = re.compile(r'\s*[—–-]\s*Off-Grid Survival Kit\s*$')

# Elements whose content never goes into the index (navigation, chrome,
# controls, code, drawings).
SKIP_TAGS = {'script', 'style', 'svg', 'nav', 'header', 'footer', 'button', 'select',
             'option', 'textarea', 'template', 'noscript', 'form', 'dialog', 'canvas',
             'iframe', 'object', 'head', 'title', 'meta', 'link'}
VOID_TAGS = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta',
             'param', 'source', 'track', 'wbr'}
# Inline elements: no word break around them ("<b>bowl</b>ine" stays one word).
INLINE_TAGS = {'a', 'abbr', 'b', 'bdi', 'bdo', 'cite', 'code', 'data', 'dfn', 'em', 'i',
               'kbd', 'mark', 'q', 's', 'samp', 'small', 'span', 'strong', 'sub', 'sup',
               'time', 'u', 'var', 'label'}
TARGET_TAGS = ('h2', 'h3', 'h4', 'summary')     # what common.js searches for "f"

# Words not worth keeping in the "x" tail-word list.
STOP = set('''a an and are as at be but by can do does for from had has have he her his how i if in
into is it its me my no not of on or our she so than that the their them then there these they this
those to too up us was we were what when where which who why will with without you your'''.split())


# ---------------------------------------------------------------------------
# Minimal DOM: html.parser events -> tree of Node / str
# ---------------------------------------------------------------------------
class Node:
    __slots__ = ('tag', 'attrs', 'children', 'parent')

    def __init__(self, tag, attrs, parent):
        self.tag = tag
        self.attrs = attrs
        self.children = []
        self.parent = parent

    def get(self, name, default=None):
        return self.attrs.get(name, default)


class TreeBuilder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node('#root', {}, None)
        self.cur = self.root

    def handle_starttag(self, tag, attrs):
        node = Node(tag, {k: (v if v is not None else '') for k, v in attrs}, self.cur)
        self.cur.children.append(node)
        if tag not in VOID_TAGS:
            self.cur = node

    def handle_startendtag(self, tag, attrs):
        node = Node(tag, {k: (v if v is not None else '') for k, v in attrs}, self.cur)
        self.cur.children.append(node)

    def handle_endtag(self, tag):
        # Tolerant close: pop up to the matching open element if there is one.
        n = self.cur
        while n is not None and n.tag != tag:
            n = n.parent
        if n is not None and n.parent is not None:
            self.cur = n.parent

    def handle_data(self, data):
        self.cur.children.append(data)


def parse(path):
    tb = TreeBuilder()
    with open(path, encoding='utf-8') as fh:
        tb.feed(fh.read())
    tb.close()
    return tb.root


def iter_nodes(node):
    """All element nodes in document order (including node itself)."""
    stack = [node]
    while stack:
        n = stack.pop()
        if isinstance(n, Node):
            yield n
            stack.extend(reversed([c for c in n.children if isinstance(c, Node)]))


def find_first(node, tag):
    for n in iter_nodes(node):
        if n.tag == tag:
            return n
    return None


def collapse(s):
    return re.sub(r'\s+', ' ', s).strip()


def raw_text(node):
    """Like DOM textContent: every descendant text node, nothing skipped."""
    out = []
    stack = [node]
    while stack:
        n = stack.pop()
        if isinstance(n, str):
            out.append(n)
        else:
            stack.extend(reversed(n.children))
    return ''.join(out)


def norm_heading(node):
    """Heading text exactly as common.js will compare it (textContent, collapsed)."""
    return collapse(raw_text(node))


def is_skipped(node):
    if node.tag in SKIP_TAGS:
        return True
    if 'hidden' in node.attrs or node.get('aria-hidden') == 'true':
        return True
    cls = node.get('class', '').split()
    return 'toc' in cls or 'skip-link' in cls


def visible_text(node):
    """Readable text of a subtree, with word breaks around block elements."""
    out = []

    def rec(n):
        if isinstance(n, str):
            out.append(n)
            return
        if is_skipped(n):
            return
        block = n.tag not in INLINE_TAGS
        if block:
            out.append(' ')
        for c in n.children:
            rec(c)
        if block:
            out.append(' ')
    rec(node)
    return collapse(''.join(out))


def summary_parts(summary):
    """(main heading, sub-line) of a <summary>; the .sub span is the sub-line."""
    main, sub = [], []

    def rec(n, into):
        if isinstance(n, str):
            into.append(n)
            return
        if is_skipped(n):
            return
        if 'sub' in n.get('class', '').split():
            sub.append(' ' + visible_text(n) + ' ')
            return
        for c in n.children:
            rec(c, into)
    for c in summary.children:
        rec(c, main)
    return collapse(''.join(main)), collapse(''.join(sub))


# ---------------------------------------------------------------------------
# Cut one page into entries
# ---------------------------------------------------------------------------
def nearest_id(node):
    n = node
    while n is not None and isinstance(n, Node):
        i = n.get('id')
        if i and i != 'main':
            return n, i
        if n.tag == 'main':
            return None, ''
        n = n.parent
    return None, ''


def first_target_inside(node):
    """First h2/h3/h4/summary inside node (document order), like querySelector."""
    for n in iter_nodes(node):
        if n is not node and n.tag in TARGET_TAGS:
            return n
    return None


def page_entries(rel, root):
    title_node = find_first(root, 'title')
    pt = TITLE_SUFFIX.sub('', collapse(raw_text(title_node))) if title_node else rel
    main = find_first(root, 'main') or find_first(root, 'body') or root
    h1 = find_first(root, 'h1')
    page_h = collapse(raw_text(h1)) if h1 else pt
    desc = ''
    for m in iter_nodes(root):
        if m.tag == 'meta' and m.get('name') == 'description':
            desc = collapse(m.get('content', ''))
            break

    entries = []
    intro = {'node': None, 'h': page_h, 'a': '', 'buf': [], 'kind': 'page'}
    state = {'cur': intro, 'h2': None, 'h3': None}

    def new_entry(node, heading, kind, ctx, target):
        """target = the element common.js should land on (heading or <details>)."""
        anchor_node, anchor = nearest_id(target)
        e = {'node': target, 'h': heading, 'a': anchor, 'buf': [], 'kind': kind, 'c': ctx}
        # "f" is needed when the anchor is some ancestor and the heading is not
        # the first thing in it (otherwise jumping to the anchor shows it anyway).
        if anchor_node is not target:
            scope = anchor_node if anchor_node is not None else main
            first = first_target_inside(scope)
            own = node  # the h2/h3 itself, or the <summary> of a card
            if first is not own:
                e['f'] = norm_heading(own)
                e['scope'] = scope
                e['own'] = own
        entries.append(e)
        return e

    def ctx_path():
        return ' › '.join(x for x in (state['h2'], state['h3']) if x)

    def walk(n, in_details):
        if isinstance(n, str):
            state['cur']['buf'].append(n)
            return
        if is_skipped(n) or n.tag == 'h1':
            return
        if n.tag in ('h2', 'h3') and not in_details:
            heading = visible_text(n)
            if n.tag == 'h2':
                state['h2'], state['h3'] = heading, None
                ctx = ''
            else:
                ctx = state['h2'] or ''
                state['h3'] = heading
            state['cur'] = new_entry(n, heading, n.tag, ctx, n)
            return
        if n.tag == 'details':
            summary = next((c for c in n.children if isinstance(c, Node) and c.tag == 'summary'), None)
            if summary is not None:
                heading, sub = summary_parts(summary)
                saved = state['cur']
                e = new_entry(summary, heading, 'details', ctx_path(), n)
                e['s'] = sub
                state['cur'] = e
                for c in n.children:
                    if c is not summary:
                        walk(c, True)
                state['cur'] = saved
                return
        block = n.tag not in INLINE_TAGS
        if block:
            state['cur']['buf'].append(' ')
        for c in n.children:
            walk(c, in_details)
        if block:
            state['cur']['buf'].append(' ')

    for c in main.children:
        walk(c, False)

    out = []
    intro_text = collapse(''.join(intro['buf']))
    if not entries and not intro_text:
        intro_text = desc          # app-style page: describe it with its meta description
    if intro_text:
        out.append(finish(rel, pt, intro, intro_text))
    for e in entries:
        out.append(finish(rel, pt, e, collapse(''.join(e['buf']))))
    return out, root


def finish(rel, pt, e, text):
    entry = {'p': rel, 'pt': pt, 'h': e['h'], 'a': e['a']}
    if e.get('c'):
        entry['c'] = e['c']
    if e.get('s'):
        entry['s'] = e['s']
    if e.get('f'):
        entry['f'] = e['f']
    t, tail = cap(text)
    entry['t'] = t
    if tail:
        entry['x'] = tail
    # private (stripped before writing): for validation
    entry['_scope'] = e.get('scope')
    entry['_own'] = e.get('own')
    return entry


def cap(text):
    """Trim to TEXT_CAP at a word boundary; return (text, distinct tail words)."""
    if len(text) <= TEXT_CAP:
        return text, ''
    cut = text.rfind(' ', 0, TEXT_CAP)
    if cut < TEXT_CAP * 0.8:
        cut = TEXT_CAP
    head, rest = text[:cut].rstrip(), text[cut:]
    have = set(w.lower() for w in re.findall(r'\w+', head))
    tail, seen = [], set()
    for w in re.findall(r'\w+', rest):
        lw = w.lower()
        if len(lw) < 3 or lw in STOP or lw in have or lw in seen or lw.isdigit():
            continue
        seen.add(lw)
        tail.append(lw)
    return head + ' …', ' '.join(tail)


# ---------------------------------------------------------------------------
# Hand-written entries for app features that have no guide text.
# "a" for map/ is a router hash handled by assets/js/map/main.js, validated
# against the page's drawer tabs (data-tab) rather than element ids.
# ---------------------------------------------------------------------------
HAND_ENTRIES = [
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Save map area offline', 'a': 'tab=offline',
     't': 'Download the map for an area so it works with no signal: open the Map, menu → Offline maps → '
          'Save this area. Pick extra zoom levels of detail and include elevation data (altitude, slope, '
          'contours). Do home, routes and destinations before you lose signal.',
     'k': 'offline maps download save area tiles no signal topo elevation cache'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'SOS beacon', 'a': 'sos',
     't': 'Full-screen, flashing display of your GPS coordinates (decimal degrees, DMS, MGRS and a '
          'phonetic read-out) so you can read them to a dispatcher or show them to rescuers.',
     'k': 'sos emergency rescue help coordinates position location flashing screen dispatcher 911 112'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Share location by QR code', 'a': 'tab=share',
     't': 'Show your GPS position (or the map centre) as a QR code another phone can scan with its '
          'camera, with no network. geo: link or plain text with coordinates and MGRS.',
     'k': 'qr code share location send position coordinates scan another phone'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Triangulate your position', 'a': 'tab=triangulate',
     't': 'Find where you are from compass bearings to 2–3 landmarks you can see and can find on the map '
          '(peaks, towers, bridges). Best when the landmarks are 60–120° apart. Magnetic or true bearings.',
     'k': 'triangulate triangulation resection bearings landmarks where am i lost position compass'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Backtrack / return to start', 'a': 'backtrack',
     't': 'Get back the way you came: with GPS on, the map keeps a breadcrumb trail automatically and the '
          'Back button guides you along it to where you started, warning you if you stray off the trail. '
          'Saved tracks can be followed back too: Tracks → Backtrack.',
     'k': 'backtrack return start way back retrace breadcrumb trail track record route lost tracback'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': '3D terrain view', 'a': '3d',
     't': 'See the area around you in 3D: hills and valleys from radar-measured elevation (SRTM) with the map or '
          'satellite photo draped over them, your position, waypoints and tracks. Rotate, tilt and zoom. Works offline '
          'for areas saved with elevation data.',
     'k': '3d three dimensional terrain relief mountains hills valleys elevation radar srtm view tilt'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Live satellite pictures & rain radar', 'a': 'live',
     't': 'The newest real pictures of your area: weather satellites every 10–15 minutes (clouds, dust storms, smoke), '
          'rain radar for the past 2 hours, and NASA\'s daily satellite photo. Needs signal.',
     'k': 'live satellite now weather clouds storm dust smoke radar rain picture photo footage nasa meteosat goes'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Navigate to a waypoint', 'a': 'tab=waypoints',
     't': 'Pin waypoints (camp, car, water, rally point) at the crosshair or your GPS position, then tap Go '
          'for a live arrow, distance and bearing to it. Long-press the map to drop a pin.',
     'k': 'waypoint navigate go to pin mark camp car rally point distance bearing direction'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Coordinates, MGRS & UTM', 'a': 'tab=position',
     't': 'See your position as lat/lon (DD, DMS, DDM), MGRS and UTM, and go to typed coordinates.',
     'k': 'coordinates gps position mgrs utm grid reference latitude longitude go to'},
    {'p': 'map/index.html', 'pt': 'Map', 'h': 'Sunrise, sunset & moon', 'a': 'tab=sun',
     't': 'Sunrise, sunset, twilight, daylight left and moon phase for your GPS position or the map centre, '
          'on any date — computed on the phone, no signal needed.',
     'k': 'sun moon sunrise sunset daylight dark twilight moonrise phase'},
    {'p': 'compass/index.html', 'pt': 'Compass', 'h': 'Compass', 'a': '',
     't': 'Live compass that works offline: heading, true/magnetic north with automatic declination, '
          'bearing lock with steering, back bearing, sun check, waypoint direction, camera sighting and '
          'bearing log.',
     'k': 'compass heading bearing north direction declination magnetic true navigate'},
]
MAP_ROUTES = {'sos', 'compass', 'backtrack', '3d', 'live'}     # non-tab hashes handled by map/main.js

# Curated keywords ("k") for the life-critical sections, so the obvious
# panicked query lands on them first. Keyed by (page, exact heading).
# A key that no longer matches a heading only prints a warning.
KEYWORDS = {
    ('water/index.html', 'Boiling: the most reliable method'): 'boil water purify drinking water rolling boil',
    ('water/index.html', 'Chemical treatment'): 'bleach chlorine iodine tablets purify water',
    ('firstaid/index.html', 'Severe bleeding'): 'bleed bleeding stop the bleed blood loss hemorrhage',
    ('firstaid/index.html', '3. Tourniquet (arms and legs only)'): 'tourniquet stop bleeding arm leg limb',
    ('firstaid/index.html', 'Snakebite'): 'snake bite snakebite viper rattlesnake venom',
    ('firstaid/index.html', 'CPR basics'): 'cpr not breathing cardiac arrest heart chest compressions',
    ('firstaid/index.html', 'Hypothermia'): 'hypothermia cold freezing shivering',
    ('firstaid/index.html', 'Burns'): 'burn burns scald',
    ('firstaid/index.html', 'Choking'): 'choking choke heimlich',
    ('emergency/index.html', '1. Lost while hiking'): 'lost hiking stop stay put found',
    ('emergency/index.html', 'Signalling'): 'signal for help rescue signal',
}


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
def all_ids(root):
    return {n.get('id') for n in iter_nodes(root) if n.get('id')}


def validate(entries, trees):
    errors = []
    for e in entries:
        p, a = e['p'], e['a']
        root = trees.get(p)
        if root is None:
            errors.append('%s: page not found' % p)
            continue
        if p == 'map/index.html':
            tabs = {n.get('data-tab') for n in iter_nodes(root) if n.get('data-tab')}
            ok = a in MAP_ROUTES or (a.startswith('tab=') and a[4:] in tabs)
            if not ok:
                errors.append('%s#%s: unknown map route (%s)' % (p, a, e['h']))
            continue
        if a and a not in all_ids(root):
            errors.append('%s#%s: anchor id missing (%s)' % (p, a, e['h']))
        if e.get('f'):
            # common.js picks the FIRST h2/h3/h4/summary in the anchor whose
            # text equals f — that must be this entry's own heading.
            hits = [n for n in iter_nodes(e['_scope']) if n.tag in TARGET_TAGS and norm_heading(n) == e['f']]
            if not hits:
                errors.append('%s#%s: find text not found: %r' % (p, a, e['f']))
            elif hits[0] is not e['_own']:
                errors.append('%s#%s: find text %r first matches a different heading' % (p, a, e['f']))
    return errors


# ---------------------------------------------------------------------------
def discover():
    pages = []
    for d in sorted(os.listdir(ROOT)):
        if d in SKIP_DIRS or d.startswith('.'):
            continue
        f = os.path.join(ROOT, d, 'index.html')
        if os.path.isfile(f):
            pages.append(d + '/index.html')
    return pages


def main():
    trees, entries = {}, []
    hand_pages_top = {h['p'] for h in HAND_ENTRIES if h['a'] == ''}
    for rel in discover():
        es, root = page_entries(rel, parse(os.path.join(ROOT, rel)))
        trees[rel] = root
        # An app-style page with no guide sections (e.g. compass/) that already
        # has a hand-written entry doesn't need its auto-generated overview too.
        if rel in hand_pages_top and len(es) <= 1:
            continue
        entries.extend(es)
    map_path = os.path.join(ROOT, 'map', 'index.html')
    if os.path.isfile(map_path):
        trees['map/index.html'] = parse(map_path)
    for h in HAND_ENTRIES:
        if h['p'] not in trees and os.path.isfile(os.path.join(ROOT, h['p'])):
            trees[h['p']] = parse(os.path.join(ROOT, h['p']))
        entries.append(dict(h))

    # curated keywords
    used = set()
    for e in entries:
        key = (e['p'], e['h'])
        if key in KEYWORDS and 'k' not in e:
            e['k'] = KEYWORDS[key]
            used.add(key)
    for key in sorted(set(KEYWORDS) - used):
        print('warning: KEYWORDS target not found: %s / %r' % key, file=sys.stderr)

    errors = validate(entries, trees)
    if errors:
        print('SEARCH INDEX NOT WRITTEN — %d broken anchor(s):' % len(errors), file=sys.stderr)
        for err in errors:
            print('  ' + err, file=sys.stderr)
        sys.exit(1)

    # drop private validation keys and empty optional fields ("a" is always kept)
    clean = [{k: v for k, v in e.items() if not k.startswith('_') and (v != '' or k == 'a')}
             for e in entries]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    data = json.dumps(clean, ensure_ascii=False, separators=(',', ':'))
    with open(OUT, 'w', encoding='utf-8') as fh:
        fh.write(data)
    size = len(data.encode('utf-8'))
    per_page = {}
    for e in clean:
        per_page[e['p']] = per_page.get(e['p'], 0) + 1
    print('search-index.json: %d entries, %.1f KB (%d bytes), %d pages, all anchors valid'
          % (len(clean), size / 1024, size, len(per_page)))
    for p in sorted(per_page):
        print('  %-24s %3d' % (p, per_page[p]))


if __name__ == '__main__':
    main()
