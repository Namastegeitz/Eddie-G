#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build the Off-Grid Survival Kit Emergency Guide.

Generates BOTH outputs from the single content source scripts/emergency_content.py:
  emergency/off-grid-emergency-guide.pdf   printable multi-page field guide (US Letter, fits A4)
  emergency/index.html                     the in-app Emergency page (same scenarios and cards)

Usage, from the app root (apps/off-grid-survival-kit/):
    python3 scripts/build_emergency.py

Needs only Python 3 and reportlab (built-in Helvetica fonts, no font files).
The PDF is built in passes until the page numbers in the quick-action index,
cross-references and "Page X of Y" footers are stable.
"""

import html
import os
import re
import sys

from reportlab.graphics.shapes import Drawing, PolyLine
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (BaseDocTemplate, CondPageBreak, Flowable, Frame,
                                KeepTogether, NextPageTemplate, PageBreak,
                                PageTemplate, Paragraph, Spacer, Table, TableStyle)

HERE = os.path.dirname(os.path.abspath(__file__))
APP_ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True   # don't leave __pycache__ in scripts/
import emergency_content as C  # noqa: E402

OUT_DIR = os.path.join(APP_ROOT, "emergency")
PDF_PATH = os.path.join(OUT_DIR, C.PDF_FILENAME)
HTML_PATH = os.path.join(OUT_DIR, "index.html")

# ===========================================================================
# Shared markup helpers
# ===========================================================================
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")
REF_RE = re.compile(r"\[\[ref:([\w-]+)\|([^\]]+)\]\]")
USED_REFS = set()


def plain(s):
    """Markup stripped (for outlines, checks)."""
    s = REF_RE.sub(lambda m: m.group(2), s)
    return BOLD_RE.sub(lambda m: m.group(1), s)


def check_pdf_chars(s):
    """Helvetica (standard Type 1) only has Windows-1252 glyphs: fail loudly otherwise."""
    try:
        s.encode("cp1252")
    except UnicodeEncodeError as e:
        bad = s[e.start:e.end]
        raise SystemExit("Unsupported character %r (U+%04X) for the PDF in: %r"
                         % (bad, ord(bad[0]), s[:80]))


def esc(s):
    return html.escape(s, quote=False)


# ---- PDF inline markup ----
PAGES = {}        # anchor key -> page number (from the previous pass)
PASS_PAGES = {}   # anchor key -> page number (recorded in this pass)
STATE = {"section": "", "total": 0, "carried": "", "page_sections": [], "opens_with_heading": False}


def pdf_markup(s):
    check_pdf_chars(plain(s))
    out = esc(s)

    def ref(m):
        key, text = m.group(1), m.group(2)
        USED_REFS.add(key)
        page = PAGES.get(key)
        num = str(page) if page else "00"
        return '<a href="#%s" color="black">%s (p.&#160;%s)</a>' % (key, text, num)

    out = REF_RE.sub(ref, out)
    out = BOLD_RE.sub(r"<b>\1</b>", out)
    return out


# ---- HTML inline markup ----
def html_markup(s):
    out = esc(s)

    def ref(m):
        key, text = m.group(1), m.group(2)
        USED_REFS.add(key)
        return '<a href="#%s">%s</a>' % (key, text)

    out = REF_RE.sub(ref, out)
    out = BOLD_RE.sub(r"<strong>\1</strong>", out)
    return out


# ===========================================================================
# PDF
# ===========================================================================
PAGE_W, PAGE_H = letter
# 0.7 in side margins: a Letter page printed on A4 at "actual size" loses only
# about 0.12 in per side, so nothing is clipped on A4 either.
MARGIN_L = MARGIN_R = 0.7 * inch
MARGIN_TOP = 0.8 * inch      # running header sits above this
MARGIN_BOTTOM = 0.8 * inch   # footer sits below this
FRAME_W = PAGE_W - MARGIN_L - MARGIN_R

BLACK = colors.black
GREY_FILL = colors.Color(0.90, 0.90, 0.90)
LIGHT_FILL = colors.Color(0.95, 0.95, 0.95)
MID_GREY = colors.Color(0.35, 0.35, 0.35)
RULE_GREY = colors.Color(0.6, 0.6, 0.6)

BODY = ParagraphStyle("body", fontName="Helvetica", fontSize=10, leading=13.2, spaceAfter=3)
BODY_TIGHT = ParagraphStyle("bodyt", parent=BODY, spaceAfter=0)
SMALL = ParagraphStyle("small", parent=BODY, fontSize=9, leading=11.6, spaceAfter=0)
LIST = ParagraphStyle("list", parent=BODY, fontSize=9.5, leading=12.2, spaceAfter=0)
LABEL = ParagraphStyle("label", fontName="Helvetica-Bold", fontSize=8, leading=9.5, textColor=MID_GREY)
KICKER = ParagraphStyle("kicker", fontName="Helvetica-Bold", fontSize=9, leading=11, textColor=MID_GREY, spaceAfter=1)
H1 = ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=28, leading=30, spaceAfter=2)
H2 = ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=19, leading=23, spaceAfter=2)
H3 = ParagraphStyle("h3", fontName="Helvetica-Bold", fontSize=11.5, leading=14, spaceBefore=7, spaceAfter=3)
SUB = ParagraphStyle("sub", parent=BODY, fontSize=10, leading=12.5, textColor=MID_GREY, spaceAfter=6)
KEY = ParagraphStyle("key", parent=BODY, fontName="Helvetica", fontSize=11, leading=14.5, spaceAfter=0)
COL_HEAD = ParagraphStyle("colhead", fontName="Helvetica-Bold", fontSize=10, leading=12, textColor=colors.white)
TH = ParagraphStyle("th", fontName="Helvetica-Bold", fontSize=9.5, leading=12)
TD = ParagraphStyle("td", parent=BODY, fontSize=9.5, leading=12.2, spaceAfter=0)
BANNER = ParagraphStyle("banner", fontName="Helvetica-Bold", fontSize=17, leading=20, textColor=colors.white)
BANNER_SMALL = ParagraphStyle("bannersm", fontName="Helvetica", fontSize=9.5, leading=12, textColor=colors.white)
INDEX_ROW = ParagraphStyle("idx", parent=BODY, fontSize=10, leading=12.5, spaceAfter=0)
INDEX_NUM = ParagraphStyle("idxn", parent=INDEX_ROW, fontName="Helvetica-Bold", alignment=TA_RIGHT)
CENTER_SMALL = ParagraphStyle("csm", parent=SMALL, alignment=TA_CENTER)


def P(text, style=BODY):
    return Paragraph(pdf_markup(text), style)


class Heading(Paragraph):
    """A paragraph that registers named destinations, outline entries,
    its page number (for the index) and the running-header section name."""

    def __init__(self, text, style, anchors=(), section=None):
        Paragraph.__init__(self, pdf_markup(text), style)
        self.anchors = list(anchors)   # (key, outline title or None, level)
        self.section = section

    def draw(self):
        c = self.canv
        for key, title, level in self.anchors:
            c.bookmarkHorizontal(key, 0, self.height + 8)
            if title:
                c.addOutlineEntry(title, key, level=level, closed=False if level == 0 else True)
            PASS_PAGES[key] = c.getPageNumber()
        if self.section is not None:
            STATE["section"] = self.section
            STATE["page_sections"].append(self.section)
            _, top = c.absolutePosition(0, self.height)
            if not STATE["page_sections"][:-1] and top > PAGE_H - MARGIN_TOP - 40:
                STATE["opens_with_heading"] = True   # only a kicker line above it
        Paragraph.draw(self)


class NumBadge(Flowable):
    """Black circle with a white step number (prints in pure black and white)."""

    def __init__(self, n, r=6.6):
        Flowable.__init__(self)
        self.n, self.r = n, r

    def wrap(self, aw, ah):
        return (2 * self.r, 2 * self.r)

    def draw(self):
        c = self.canv
        c.setFillColor(BLACK)
        c.circle(self.r, self.r, self.r, stroke=0, fill=1)
        c.setFillColor(colors.white)
        c.setFont("Helvetica-Bold", 8.5 if self.n < 10 else 7.5)
        c.drawCentredString(self.r, self.r - 3, str(self.n))


class Mark(Flowable):
    """Bullet glyphs drawn as vector shapes: 'box' (tick box), 'x' (do not), 'dot'."""

    def __init__(self, kind, size=7.5):
        Flowable.__init__(self)
        self.kind, self.size = kind, size

    def wrap(self, aw, ah):
        return (self.size, self.size)

    def draw(self):
        c, s = self.canv, self.size
        c.setStrokeColor(BLACK)
        c.setFillColor(BLACK)
        if self.kind == "box":
            c.setLineWidth(0.9)
            c.rect(0, 0, s, s, stroke=1, fill=0)
        elif self.kind == "x":
            c.setLineWidth(1.6)
            c.setLineCap(1)
            c.line(0.6, 0.6, s - 0.6, s - 0.6)
            c.line(0.6, s - 0.6, s - 0.6, 0.6)
        else:
            c.circle(s / 2.0, s / 2.0, 1.8, stroke=0, fill=1)


class MorseGlyph(Flowable):
    """Dots and dashes drawn as shapes, so they can't be misread in print."""
    DOT, DASH, GAP, H = 3.6, 11.0, 2.8, 6.0

    def __init__(self, code):
        Flowable.__init__(self)
        self.code = code

    def _width(self):
        w = 0
        for ch in self.code:
            w += (self.DOT if ch == "." else self.DASH) + self.GAP
        return w - self.GAP

    def wrap(self, aw, ah):
        return (self._width(), self.H)

    def draw(self):
        c = self.canv
        c.setFillColor(BLACK)
        x, mid = 0, self.H / 2.0
        for ch in self.code:
            if ch == ".":
                c.circle(x + self.DOT / 2.0, mid, self.DOT / 2.0, stroke=0, fill=1)
                x += self.DOT
            else:
                c.roundRect(x, mid - 1.6, self.DASH, 3.2, 1.5, stroke=0, fill=1)
                x += self.DASH
            x += self.GAP


# Ground-to-air symbols as polylines in a 60x60 box (SVG coordinates, y down).
# Shared with the HTML page so both draw identical shapes.
G2A_PATHS = {
    "V": [[(12, 10), (30, 50), (48, 10)]],
    "X": [[(12, 10), (48, 50)], [(48, 10), (12, 50)]],
    "N": [[(14, 50), (14, 10), (46, 50), (46, 10)]],
    "Y": [[(12, 10), (30, 30), (48, 10)], [(30, 30), (30, 52)]],
    "ARROW": [[(8, 30), (52, 30)], [(36, 14), (52, 30), (36, 46)]],
}


def g2a_drawing(sym, size=46):
    k = size / 60.0
    d = Drawing(size, size)
    for line in G2A_PATHS[sym]:
        pts = []
        for x, y in line:
            pts += [x * k, (60 - y) * k]
        d.add(PolyLine(pts, strokeWidth=6.5 * k, strokeColor=BLACK,
                       strokeLineCap=1, strokeLineJoin=1, fillColor=None))
    return d


# ---- building blocks -------------------------------------------------------
def numbered(items, width=FRAME_W, style=LIST, start=1):
    rows = [[NumBadge(i), Paragraph(pdf_markup(t), style)] for i, t in enumerate(items, start)]
    t = Table(rows, colWidths=[20, width - 20], hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (0, -1), 0.5),
        ("TOPPADDING", (1, 0), (1, -1), 1.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3.2),
    ]))
    return t


def bullets(items, kind="dot", width=FRAME_W, style=LIST):
    rows = [[Mark(kind), Paragraph(pdf_markup(t), style)] for t in items]
    t = Table(rows, colWidths=[14, width - 14], hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (0, -1), 2.6),
        ("TOPPADDING", (1, 0), (1, -1), 0),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2.6),
    ]))
    return t


CALLOUT_WORD = {"danger": "DANGER", "warn": "CAUTION", "info": "NOTE", "ok": "GOOD PRACTICE"}


def callout(kind, title, text, width=FRAME_W):
    head = "%s — %s:" % (CALLOUT_WORD.get(kind, "NOTE"), title.upper()) if title else CALLOUT_WORD[kind] + ":"
    p = Paragraph("<b>%s</b> %s" % (esc(head), pdf_markup(text)), TD)
    check_pdf_chars(head)
    bar, box_w, box_c, fill = {"danger": (7, 1.6, BLACK, colors.white),
                               "warn": (5, 1.0, BLACK, LIGHT_FILL)}.get(kind, (3, 0.6, MID_GREY, LIGHT_FILL))
    t = Table([["", p]], colWidths=[bar, width - bar], hAlign="LEFT")
    st = [("LEFTPADDING", (1, 0), (1, -1), 9), ("RIGHTPADDING", (1, 0), (1, -1), 8),
          ("LEFTPADDING", (0, 0), (0, -1), 0), ("RIGHTPADDING", (0, 0), (0, -1), 0),
          ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
          ("BACKGROUND", (0, 0), (0, -1), box_c), ("BACKGROUND", (1, 0), (1, -1), fill),
          ("BOX", (0, 0), (-1, -1), box_w, box_c)]
    t.setStyle(TableStyle(st))
    return [Spacer(1, 4), t, Spacer(1, 4)]


def key_box(text, width=FRAME_W, label="REMEMBER"):
    p = Paragraph("<b>%s:</b> %s" % (label, pdf_markup(text)), KEY)
    t = Table([[p]], colWidths=[width], hAlign="LEFT")
    t.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 2, BLACK),
        ("BACKGROUND", (0, 0), (-1, -1), GREY_FILL),
        ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def two_column_lists(left_head, left_items, right_head, right_items):
    gap = 10
    cw = (FRAME_W - gap) / 2.0
    inner = cw - 12
    data = [
        [Paragraph(left_head, COL_HEAD), "", Paragraph(right_head, COL_HEAD)],
        [bullets(left_items, "x", inner), "", bullets(right_items, "box", inner)],
    ]
    t = Table(data, colWidths=[cw, gap, cw], hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (0, 0), BLACK),
        ("BACKGROUND", (2, 0), (2, 0), BLACK),
        ("BOX", (0, 0), (0, 1), 1.2, BLACK),
        ("BOX", (2, 0), (2, 1), 1.2, BLACK),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, 0), 3), ("BOTTOMPADDING", (0, 0), (-1, 0), 4),
        ("TOPPADDING", (0, 1), (-1, 1), 6), ("BOTTOMPADDING", (0, 1), (-1, 1), 4),
    ]))
    return t


def grid_table(header, rows, col_widths, header_fill=GREY_FILL, row_heights=None, font=TD):
    data = [[Paragraph(pdf_markup(h), TH) for h in header]]
    for r in rows:
        data.append([Paragraph(pdf_markup(c), font) if isinstance(c, str) else c for c in r])
    t = Table(data, colWidths=col_widths, rowHeights=row_heights, hAlign="LEFT", repeatRows=1)
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.7, BLACK),
        ("BACKGROUND", (0, 0), (-1, 0), header_fill),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t


def section_heading(kicker, title, key, outline, level=0, section=None, extra_anchors=()):
    anchors = list(extra_anchors) + [(key, outline, level)]
    return [Paragraph(esc(kicker), KICKER),
            Heading(title, H2, anchors=anchors, section=section or title),
            Spacer(1, 2)]


# ---- page decorations ------------------------------------------------------
def draw_footer(canv, doc):
    canv.saveState()
    y_line = 0.62 * inch
    canv.setStrokeColor(BLACK)
    canv.setLineWidth(0.6)
    canv.line(MARGIN_L, y_line, PAGE_W - MARGIN_R, y_line)
    canv.setFillColor(BLACK)
    canv.setFont("Helvetica", 8)
    canv.drawString(MARGIN_L, 0.45 * inch, C.FOOTER)
    canv.setFont("Helvetica-Bold", 9)
    total = STATE["total"] or 0
    label = "Page %d of %d" % (doc.page, total) if total else "Page %d" % doc.page
    canv.drawRightString(PAGE_W - MARGIN_R, 0.45 * inch, label)
    canv.restoreState()


def on_cover(canv, doc):
    canv.showOutline()
    draw_footer(canv, doc)


def on_page_start(canv, doc):
    STATE["carried"] = STATE["section"]
    STATE["page_sections"] = []
    STATE["opens_with_heading"] = False


def on_page_end(canv, doc):
    """Running header, drawn at page end so it can name every section on the page:
    the one carried over from the previous page (unless the page opens with a new
    heading) followed by any that start here."""
    canv.saveState()
    y = PAGE_H - 0.5 * inch
    canv.setFillColor(BLACK)
    canv.setFont("Helvetica-Bold", 8.5)
    canv.drawString(MARGIN_L, y, "EMERGENCY: call 911 (US/Canada) or 112 (Europe and many countries)")
    canv.setFont("Helvetica", 8.5)
    names = list(STATE["page_sections"])
    if STATE["carried"] and not STATE["opens_with_heading"]:
        names.insert(0, STATE["carried"])
    sec = " / ".join(dict.fromkeys(names))
    if sec:
        check_pdf_chars(sec)
        canv.drawRightString(PAGE_W - MARGIN_R, y, sec)
    canv.setLineWidth(0.6)
    canv.line(MARGIN_L, y - 5, PAGE_W - MARGIN_R, y - 5)
    canv.restoreState()
    draw_footer(canv, doc)


# ---- sections ---------------------------------------------------------------
INDEX_ENTRIES = (
    [(s["id"], s["title"]) for s in C.SCENARIOS],
    [("water", "Water purification"), ("signals", "Signalling: ground-to-air, mirror, radio"),
     ("morse", "Morse code chart"), ("knots", "Knots"), ("firstaid", "First-aid quick steps"),
     ("contacts", "Contacts & waypoints (fill in)"), ("how-to-use", "How to use this guide")],
)


def cover_story():
    s = []
    s.append(Paragraph(esc(C.APP_NAME.upper()), KICKER))
    s.append(Heading("EMERGENCY GUIDE", H1, anchors=[("start", "Start here: priorities & index", 0)],
                     section="Start here"))
    s.append(Paragraph(esc("Printable field guide — works with no phone, no power and no signal. " + C.EDITION),
                       SUB))
    banner = Table([[Paragraph("LIFE IN DANGER? CALL 911 or 112", BANNER)],
                    [Paragraph(esc("911: US and Canada. 112: Europe and many other countries. Works on any phone with "
                                   "any network in range — try it even with \"No service\". If a call won't connect, "
                                   "send a text. Then STOP and follow the priorities below."),
                               BANNER_SMALL)]],
                   colWidths=[FRAME_W], hAlign="LEFT")
    banner.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), BLACK),
                                ("LEFTPADDING", (0, 0), (-1, -1), 10), ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                                ("TOPPADDING", (0, 0), (-1, 0), 7), ("BOTTOMPADDING", (0, -1), (-1, -1), 8)]))
    s.append(banner)
    s.append(Spacer(1, 8))

    # Fill in by hand
    half = FRAME_W / 2.0
    data = [[Paragraph("FILL IN BY HAND (pencil or waterproof pen)", COL_HEAD), ""]]
    heights = [16]
    for left, right, h_in in C.FILL_IN_PERSONAL:
        check_pdf_chars(left + right)
        data.append([Paragraph(esc(left), LABEL), Paragraph(esc(right), LABEL)])
        heights.append(h_in * inch)
    fill = Table(data, colWidths=[half, half], rowHeights=heights, hAlign="LEFT")
    fill.setStyle(TableStyle([
        ("SPAN", (0, 0), (1, 0)),
        ("GRID", (0, 1), (-1, -1), 0.8, BLACK), ("BOX", (0, 0), (-1, -1), 1.4, BLACK),
        ("BACKGROUND", (0, 0), (-1, 0), BLACK), ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("TOPPADDING", (0, 0), (-1, 0), 2.5),
    ]))
    s.append(fill)
    s.append(Spacer(1, 8))

    # Two columns: quick-action index | priorities
    gap = 12
    lw = FRAME_W * 0.42
    rw = FRAME_W - lw - gap

    def idx_rows(entries, start=None):
        rows = []
        for i, (key, title) in enumerate(entries):
            n = PAGES.get(key)
            num = str(n) if n else "00"
            lead = "%d. " % (i + 1) if start else ""
            check_pdf_chars(title)
            rows.append([Paragraph('<a href="#%s" color="black">%s%s</a>' % (key, lead, esc(title)), INDEX_ROW),
                         Paragraph('<a href="#%s" color="black">%s</a>' % (key, num), INDEX_NUM)])
        return rows

    idx = [[Paragraph("QUICK-ACTION INDEX", COL_HEAD), Paragraph("PAGE", ParagraphStyle(
        "pg", parent=COL_HEAD, alignment=TA_RIGHT, fontSize=8))]]
    idx.append([Paragraph("<b>Scenarios</b>", SMALL), ""])
    idx += idx_rows(INDEX_ENTRIES[0], start=True)
    sub_row = len(idx)
    idx.append([Paragraph("<b>Reference cards</b>", SMALL), ""])
    idx += idx_rows(INDEX_ENTRIES[1])
    it = Table(idx, colWidths=[lw - 36, 36], hAlign="LEFT")
    it.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BLACK), ("BOX", (0, 0), (-1, -1), 1.2, BLACK),
        ("LINEBELOW", (0, 2), (-1, -1), 0.4, RULE_GREY),
        ("BACKGROUND", (0, 1), (-1, 1), GREY_FILL), ("BACKGROUND", (0, sub_row), (-1, sub_row), GREY_FILL),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 2.2), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.8),
    ]))

    # Priorities column
    pr = [Paragraph("PRIORITIES", COL_HEAD)]
    stop_rows = [[Paragraph("<b>%s</b>" % letter_, ParagraphStyle("sl", fontName="Helvetica-Bold", fontSize=15, leading=15)),
                  Paragraph("<b>%s</b> — %s" % (esc(word), pdf_markup(text)), SMALL)]
                 for letter_, word, text in C.STOP]
    stop_t = Table(stop_rows, colWidths=[16, rw - 16 - 10], hAlign="LEFT")
    stop_t.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0),
                                ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0.5),
                                ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5)]))
    r3_rows = [[Paragraph("<b>%s</b>" % esc(a), SMALL), Paragraph(esc(b), SMALL)] for a, b in C.RULE_OF_3S]
    r3 = Table(r3_rows, colWidths=[58, rw - 58 - 10], hAlign="LEFT")
    r3.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0),
                            ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0.5),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 1.5)]))
    order = numbered(["**%s** — %s" % (a, b) for a, b in C.PRIORITY_ORDER], width=rw - 10, style=SMALL)
    pri_cell = [
        Paragraph("<b>1. STOP</b>", TH), Spacer(1, 2), stop_t,
        Paragraph("<b>2. Rule of 3s</b> — you can survive about:", TH), Spacer(1, 2), r3,
        Paragraph("<i>%s</i>" % esc(C.RULE_OF_3S_NOTE), SMALL), Spacer(1, 4),
        Paragraph("<b>3. In this order</b>", TH), Spacer(1, 3), order,
        Paragraph("<i>%s</i>" % esc(C.PRIORITY_NOTE), SMALL),
    ]
    for t in (C.RULE_OF_3S_NOTE, C.PRIORITY_NOTE):
        check_pdf_chars(t)
    prt = Table([[pr[0]], [pri_cell]], colWidths=[rw], hAlign="LEFT")
    prt.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BLACK), ("BOX", (0, 0), (-1, -1), 1.2, BLACK),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, 0), 2.2), ("BOTTOMPADDING", (0, 0), (-1, 0), 2.8),
        ("TOPPADDING", (0, 1), (-1, 1), 3),
    ]))
    cols = Table([[it, "", prt]], colWidths=[lw, gap, rw], hAlign="LEFT")
    cols.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0),
                              ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0),
                              ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))
    s.append(cols)
    return s


def scenario_story():
    s = []
    n = len(C.SCENARIOS)
    for i, sc in enumerate(C.SCENARIOS, start=1):
        s.append(PageBreak())
        extra = [("scenarios", "Scenarios", 0)] if i == 1 else []
        s += section_heading("SCENARIO %d OF %d" % (i, n), sc["title"], sc["id"], sc["title"], level=1,
                             section="Scenario %d: %s" % (i, sc["title"]), extra_anchors=extra)
        s.append(P(sc["sub"], SUB))
        s.append(key_box(sc["key"]))
        s.append(Paragraph("Step by step", H3))
        s.append(numbered(sc["steps"]))
        for kind, title, text in sc.get("callouts", []):
            s += callout(kind, title, text)
        s.append(Spacer(1, 6))
        s.append(KeepTogether([two_column_lists("DO NOT", sc["dont"], "HAVE READY", sc["ready"])]))
    return s


def water_story():
    W = C.WATER
    s = [PageBreak()]
    s += section_heading("REFERENCE CARD", "Water purification", "water", "Water purification", level=1,
                         section="Reference: Water purification",
                         extra_anchors=[("reference", "Reference cards", 0)])
    s.append(P(W["intro"]))
    s.append(Spacer(1, 3))
    rows = [["**%s**" % m, how, lim] for m, how, lim in W["methods"]]
    s.append(grid_table(("Method", "How", "Works against / limits"), rows, [100, 196, FRAME_W - 296]))
    s.append(Paragraph("Bleach dose (CDC)", H3))
    brows = [["**%s**" % a, "**%s**" % b, "**%s**" % c] for a, b, c in W["bleach"]]
    s.append(grid_table(W["bleach_head"], brows, [190, 130, FRAME_W - 320], font=ParagraphStyle(
        "tdb", parent=TD, fontSize=11, leading=14)))
    s.append(Spacer(1, 5))
    s.append(bullets(W["bleach_notes"]))
    for kind, title, text in W["callouts"]:
        s += callout(kind, title, text)
    return s


def signals_story():
    s = [PageBreak()]
    s += section_heading("REFERENCE CARD", "Signalling", "signals", "Signalling", level=1,
                         section="Reference: Signalling")
    s.append(Paragraph("Ground-to-air emergency code (ICAO)", H3))
    cw = FRAME_W / 5.0
    syms = [g2a_drawing(k) for k, _ in C.GROUND_TO_AIR]
    names = [Paragraph("<b>%s</b>" % ("Arrow" if k == "ARROW" else k), CENTER_SMALL) for k, _ in C.GROUND_TO_AIR]
    means = [Paragraph(esc(m), CENTER_SMALL) for _, m in C.GROUND_TO_AIR]
    for _, m in C.GROUND_TO_AIR:
        check_pdf_chars(m)
    g = Table([syms, names, means], colWidths=[cw] * 5, hAlign="LEFT")
    g.setStyle(TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "CENTER"), ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BOX", (0, 0), (-1, -1), 1, BLACK), ("INNERGRID", (0, 0), (-1, -1), 0.4, RULE_GREY),
        ("LINEBELOW", (0, 0), (-1, 0), 0, colors.white),
        ("TOPPADDING", (0, 0), (-1, 0), 7), ("BOTTOMPADDING", (0, -1), (-1, -1), 6),
    ]))
    s.append(g)
    s.append(Spacer(1, 5))
    s.append(bullets(C.GROUND_TO_AIR_NOTES))
    s.append(Spacer(1, 3))
    s.append(P(C.BODY_SIGNALS, BODY))
    s += callout("info", "Distress", C.DISTRESS_THREES)
    s.append(KeepTogether([Paragraph("Whistle", H3), bullets(C.WHISTLE)]))
    sos = Table([[Paragraph("<b>SOS</b>", ParagraphStyle("sos", fontName="Helvetica-Bold", fontSize=13, leading=14)),
                  MorseGlyph("...---...")]], colWidths=[40, 160], hAlign="LEFT")
    sos.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LEFTPADDING", (0, 0), (-1, -1), 0),
                             ("BOTTOMPADDING", (0, 0), (-1, -1), 5)]))
    s.append(KeepTogether([Paragraph("Light: SOS", H3), sos, bullets(C.LIGHT_SOS)]))
    s.append(KeepTogether([Paragraph("Signal mirror", H3), numbered(C.MIRROR_STEPS)]))
    s.append(KeepTogether([Paragraph("Phone, beacon and radio", H3), bullets(C.PHONE_RADIO)]))
    return s


def morse_story():
    s = [CondPageBreak(3.9 * inch), Spacer(1, 12)]
    s += section_heading("REFERENCE CARD", "Morse code", "morse", "Morse code", level=1,
                         section="Reference: Morse code")
    per_row = 4
    entries = C.MORSE
    rows_n = (len(entries) + per_row - 1) // per_row
    data = []
    big = ParagraphStyle("mc", fontName="Helvetica-Bold", fontSize=13, leading=14)
    for r in range(rows_n):
        row = []
        for c in range(per_row):
            idx = c * rows_n + r   # read down each column: A, B, C ...
            if idx < len(entries):
                ch, code = entries[idx]
                row += [Paragraph(ch, big), MorseGlyph(code)]
            else:
                row += ["", ""]
        data.append(row)
    cw_ch, cw_code = 22, FRAME_W / per_row - 22
    t = Table(data, colWidths=[cw_ch, cw_code] * per_row, hAlign="LEFT")
    st = [("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("BOX", (0, 0), (-1, -1), 1, BLACK),
          ("LINEBELOW", (0, 0), (-1, -2), 0.4, RULE_GREY),
          ("TOPPADDING", (0, 0), (-1, -1), 3.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
          ("LEFTPADDING", (0, 0), (-1, -1), 6)]
    for c in range(1, per_row):
        st.append(("LINEBEFORE", (2 * c, 0), (2 * c, -1), 0.8, BLACK))
    t.setStyle(TableStyle(st))
    s.append(t)
    s.append(Spacer(1, 4))
    s.append(P(C.MORSE_NOTE, SMALL))
    return s


def knots_story():
    s = [PageBreak()]
    s += section_heading("REFERENCE CARD", "Knots", "knots", "Knots", level=1, section="Reference: Knots")
    s.append(P(C.KNOTS_NOTE, SUB))
    gap = 16
    cw = (FRAME_W - gap) / 2.0

    def knot_block(k):
        return [Heading(k["name"], H3, anchors=[(k["id"], None, 2)]),
                P("**Use:** " + k["use"], SMALL), Spacer(1, 4),
                numbered(k["steps"], width=cw - 8),
                P("**Caution:** " + k["caution"], SMALL), Spacer(1, 4)]

    split = 2   # first two knots on the left, the rest on the right
    left = [f for k in C.KNOTS[:split] for f in knot_block(k)]
    right = [f for k in C.KNOTS[split:] for f in knot_block(k)]
    t = Table([[left, "", right]], colWidths=[cw, gap, cw], hAlign="LEFT")
    t.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0),
                           ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (0, -1), 8),
                           ("LEFTPADDING", (2, 0), (2, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
                           ("LINEAFTER", (0, 0), (0, -1), 0.5, RULE_GREY)]))
    s.append(t)
    return s


def first_aid_story():
    s = [PageBreak()]
    s += section_heading("REFERENCE CARD", "First-aid quick steps", "firstaid", "First aid", level=1,
                         section="Reference: First aid")
    s.append(P("Call 911 / 112 early. Protect yourself first. These are reminders — take a hands-on course.", SUB))
    for fa in C.FIRST_AID:
        block = [Heading(fa["title"], H3, anchors=[(fa["id"], fa["title"], 2)]), numbered(fa["steps"])]
        if fa.get("note"):
            block.append(P(fa["note"], SMALL))
        s.append(KeepTogether(block))
    s += callout("info", "Medicines", C.OTC_MEDS)
    return s


def contacts_story():
    s = [PageBreak()]
    s += section_heading("FILL IN BY HAND", "Contacts, meeting points & waypoints", "contacts",
                         "Contacts & waypoints (fill in)", level=0, section="Contacts & waypoints")
    s.append(P("Write clearly in pencil or waterproof pen. Include an out-of-area contact — long-distance calls and "
               "texts often work when local lines are jammed.", SMALL))
    rh = 0.35 * inch

    def blank(cols, widths, n, title):
        head = [Paragraph(esc(c), TH) for c in cols]
        t = Table([head] + [[""] * len(cols) for _ in range(n)], colWidths=widths,
                  rowHeights=[17] + [rh] * n, hAlign="LEFT")
        t.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.8, BLACK), ("BOX", (0, 0), (-1, -1), 1.4, BLACK),
                               ("BACKGROUND", (0, 0), (-1, 0), GREY_FILL), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                               ("TOPPADDING", (0, 0), (-1, 0), 2), ("BOTTOMPADDING", (0, 0), (-1, 0), 3)]))
        return KeepTogether([Paragraph(esc(title), H3), t])

    s.append(blank(C.CONTACTS_COLUMNS, [FRAME_W * 0.38, FRAME_W * 0.32, FRAME_W * 0.30], C.CONTACTS_ROWS,
                   "ICE (In Case of Emergency) contacts"))
    s.append(blank(C.MEETING_COLUMNS, [FRAME_W * 0.32, FRAME_W * 0.68], C.MEETING_ROWS,
                   "Meeting points / rendezvous"))
    s.append(blank(C.WAYPOINT_COLUMNS, [FRAME_W * 0.26, FRAME_W * 0.40, FRAME_W * 0.34], C.WAYPOINT_ROWS,
                   "Waypoints (water, shelter, trailheads, vehicle, camp)"))
    s.append(Spacer(1, 4))
    s.append(P(C.WAYPOINT_NOTE, SMALL))
    return s


def how_to_story():
    s = [PageBreak()]
    s += section_heading("ABOUT THIS GUIDE", "How to use this guide", "how-to-use", "How to use this guide",
                         level=0, section="How to use this guide")
    s.append(Spacer(1, 4))
    s.append(numbered(C.HOW_TO_USE, style=BODY_TIGHT))
    s.append(Paragraph("Disclaimer", H3))
    d = Table([[P(C.DISCLAIMER, TD)]], colWidths=[FRAME_W], hAlign="LEFT")
    d.setStyle(TableStyle([("BOX", (0, 0), (-1, -1), 1.2, BLACK), ("LEFTPADDING", (0, 0), (-1, -1), 9),
                           ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 6),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 8)]))
    s.append(d)
    s.append(Spacer(1, 8))
    s.append(P(C.SOURCES, SMALL))
    s.append(Spacer(1, 6))
    s.append(P("%s — %s. %s" % (C.APP_NAME, C.DOC_TITLE, C.EDITION), SMALL))
    return s


def build_pdf_once(path):
    PASS_PAGES.clear()
    STATE.update(section="", carried="", page_sections=[], opens_with_heading=False)
    doc = BaseDocTemplate(
        path, pagesize=letter,
        leftMargin=MARGIN_L, rightMargin=MARGIN_R, topMargin=MARGIN_TOP, bottomMargin=MARGIN_BOTTOM,
        title="%s — %s" % (C.APP_NAME, C.DOC_TITLE),
        author=C.APP_NAME, subject="Printable emergency scenarios and reference cards",
        keywords="emergency, survival, first aid, signalling, water purification",
        creator="scripts/build_emergency.py", invariant=1, lang="en-US",
    )
    cover_frame = Frame(MARGIN_L, MARGIN_BOTTOM, FRAME_W, PAGE_H - MARGIN_BOTTOM - 0.6 * inch,
                        id="cover", leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    body_frame = Frame(MARGIN_L, MARGIN_BOTTOM, FRAME_W, PAGE_H - MARGIN_BOTTOM - MARGIN_TOP,
                       id="body", leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[cover_frame], onPage=on_cover),
        PageTemplate(id="normal", frames=[body_frame], onPage=on_page_start, onPageEnd=on_page_end),
    ])
    story = cover_story()
    story.append(NextPageTemplate("normal"))
    story += scenario_story()
    story += water_story()
    story += signals_story()
    story += morse_story()
    story += knots_story()
    story += first_aid_story()
    story += contacts_story()
    story += how_to_story()
    doc.build(story)
    return dict(PASS_PAGES), doc.page


def build_pdf():
    os.makedirs(OUT_DIR, exist_ok=True)
    total = 0
    for attempt in range(1, 6):
        pages, total_new = build_pdf_once(PDF_PATH)
        stable = pages == PAGES and total_new == STATE["total"]
        PAGES.clear()
        PAGES.update(pages)
        STATE["total"] = total_new
        total = total_new
        if stable:
            break
    else:
        raise SystemExit("PDF page numbers did not stabilise")
    missing = sorted(k for k in USED_REFS if k not in PAGES)
    if missing:
        raise SystemExit("Cross-references to unknown anchors: %s" % ", ".join(missing))
    return total, attempt


# ===========================================================================
# HTML
# ===========================================================================
def g2a_svg(sym, label):
    paths = []
    for line in G2A_PATHS[sym]:
        d = "M" + " L".join("%g %g" % pt for pt in line)
        paths.append('<path d="%s"/>' % d)
    return ('<svg class="g2a-sym" viewBox="0 0 60 60" role="img" aria-label="%s" fill="none" '
            'stroke="currentColor" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">%s</svg>'
            % (esc(label), "".join(paths)))


def morse_html(code):
    vis = " ".join("•" if ch == "." else "—" for ch in code)
    spoken = " ".join("dot" if ch == "." else "dash" for ch in code)
    return '<span aria-hidden="true">%s</span><span class="sr-only">%s</span>' % (vis, spoken)


def ol_steps(items):
    return '<ol class="steps">\n%s\n</ol>' % "\n".join("  <li>%s</li>" % html_markup(t) for t in items)


def ul(items, cls=""):
    c = ' class="%s"' % cls if cls else ""
    return "<ul%s>\n%s\n</ul>" % (c, "\n".join("  <li>%s</li>" % html_markup(t) for t in items))


HTML_CALLOUT_WORD = {"danger": "Danger", "warn": "Caution", "info": "Note", "ok": "Good practice"}


def callout_html(kind, title, text):
    t = "%s: %s" % (HTML_CALLOUT_WORD[kind], title) if title else HTML_CALLOUT_WORD[kind]
    return ('<div class="callout %s"><strong class="callout-title">%s</strong><p>%s</p></div>'
            % (kind, esc(t), html_markup(text)))


PAGE_CSS = """
.pdf-actions .btn { flex: 1 1 auto; }
.pdf-note { font-size: .95rem; color: var(--muted); margin-top: 4px; }
[id] { scroll-margin-top: 76px; }
ol.sc-index { columns: 2 220px; column-gap: 24px; padding-left: 1.6em; margin: 8px 0 12px; }
ol.sc-index li { break-inside: avoid; margin: 0 0 6px; }
ol.sc-index a { display: inline-block; min-height: 32px; padding: 4px 0; }
.lists-2 { display: grid; grid-template-columns: 1fr; gap: 12px; margin: 12px 0 4px; }
@media (min-width: 720px) { .lists-2 { grid-template-columns: 1fr 1fr; } }
.lists-2 > div { border: 1px solid var(--border); border-radius: 10px; padding: 0 14px 6px; background: var(--surface-2); }
.lists-2 h3 { margin: .6em 0 .3em; font-size: 1rem; text-transform: uppercase; letter-spacing: .04em; }
ul.dont { list-style: none; padding-left: 0; }
ul.dont > li { position: relative; padding-left: 1.5em; }
ul.dont > li::before { content: "\\2715"; position: absolute; left: 0; font-weight: 800; color: var(--danger); }
ul.ready { list-style: none; padding-left: 0; }
ul.ready > li { position: relative; padding-left: 1.5em; }
ul.ready > li::before { content: ""; position: absolute; left: 0; top: .3em; width: .85em; height: .85em; border: 2px solid currentColor; border-radius: 3px; }
table.g2a td.sym { width: 76px; text-align: center; vertical-align: middle; }
table.g2a td.letter { width: 64px; font-weight: 800; font-size: 1.2rem; vertical-align: middle; }
table.g2a td { vertical-align: middle; }
.g2a-sym { width: 52px; height: 52px; display: block; margin: 0 auto; }
table.morse { font-size: 1rem; }
table.morse th.ch { width: 2.2em; font-size: 1.15rem; background: var(--surface-2); }
table.morse td.mc { font-weight: 800; letter-spacing: .08em; white-space: nowrap; }
table.morse td.mc + th.ch { border-left: 2px solid var(--border); }
table.data td.k { font-weight: 700; white-space: nowrap; }
.stop-letter { font-size: 1.4rem; font-weight: 800; width: 2em; }
@media screen and (max-width: 600px) {
  /* stack the 3-column water table into cards on phones */
  table.stack thead { display: none; }
  table.stack tr { display: block; border-bottom: 1px solid var(--border); padding: 4px 0 8px; }
  table.stack tr:last-child { border-bottom: 0; }
  table.stack th, table.stack td { display: block; border: 0; padding: 4px 12px; }
  table.stack th[scope="row"] { position: static; font-size: 1.05rem; }
  table.stack td[data-label]::before { content: attr(data-label) ": "; font-weight: 700; color: var(--muted); }
}
@media print {
  .pb { break-before: page; }
  /* long scenarios: let them flow across pages (app.css keeps details whole), one scenario per page start */
  #main details.item { break-inside: auto; }
  #scenarios details.item + details.item { break-before: page; }
  .lists-2, .lists-2 > div, table.g2a tr, table.morse { break-inside: avoid; }
  table.morse { font-size: 10pt; }
  .lists-2 { grid-template-columns: 1fr 1fr; }
  .lists-2 > div { background: #fff; }
  ul.dont > li::before { color: #000; }
  ol.sc-index { columns: 2; }
}
"""

PAGE_JS = """
(function () {
  'use strict';
  // Open the <details> that holds a link target (TOC chips, cross-references, #hash on load).
  function reveal(id) {
    var el = id && document.getElementById(id);
    if (!el) return;
    for (var d = el.closest('details'); d; d = d.parentElement && d.parentElement.closest('details')) d.open = true;
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href^="#"]');
    if (a) reveal(decodeURIComponent(a.getAttribute('href').slice(1)));
  });
  function fromHash() {
    var id = decodeURIComponent(location.hash.slice(1));
    reveal(id);
    var el = id && document.getElementById(id);
    if (el) el.scrollIntoView();
  }
  window.addEventListener('hashchange', fromHash);
  if (location.hash) document.addEventListener('DOMContentLoaded', fromHash);
})();
"""


def build_html(total_pages):
    pdf_size = os.path.getsize(PDF_PATH)
    size_txt = "%d KB" % round(pdf_size / 1024.0)
    out = []
    w = out.append
    w("<!doctype html>")
    w("<!-- GENERATED FILE: do not edit by hand.\n"
      "     Content: scripts/emergency_content.py   Layout: scripts/build_emergency.py\n"
      "     Rebuild (regenerates this page AND off-grid-emergency-guide.pdf), from the app root:\n"
      "         python3 scripts/build_emergency.py -->")
    w('<html lang="en" data-root="../" data-theme="dark">')
    w("<head>")
    w('<meta charset="utf-8">')
    w('<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">')
    w('<meta name="theme-color" content="#000000">')
    w('<meta name="apple-mobile-web-app-capable" content="yes">')
    w('<meta name="mobile-web-app-capable" content="yes">')
    w('<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">')
    w('<meta name="apple-mobile-web-app-title" content="Survival Kit">')
    w('<meta property="og:type" content="website">')
    w('<meta property="og:site_name" content="Off-Grid Survival Kit">')
    w('<meta property="og:title" content="Emergency — Off-Grid Survival Kit">')
    w('<meta property="og:description" content="Printable emergency guide: what to do when lost, stranded, in a storm, flood, wildfire, power outage or with an injury far from help.">')
    w('<meta property="og:url" content="https://namastegeitz.github.io/Eddie-G/emergency/">')
    w('<meta property="og:image" content="https://namastegeitz.github.io/Eddie-G/assets/icons/og-card.png">')
    w('<meta property="og:image:width" content="1200">')
    w('<meta property="og:image:height" content="630">')
    w('<meta property="og:image:alt" content="Off-Grid Survival Kit: offline map, compass and survival guides">')
    w('<meta name="twitter:card" content="summary_large_image">')
    w('<meta name="description" content="Printable emergency guide: step-by-step responses for nine emergencies '
      'plus water, signalling, Morse, knots and first-aid reference cards.">')
    w("<title>Emergency — Off-Grid Survival Kit</title>")
    w('<link rel="manifest" href="../manifest.webmanifest">')
    w('<link rel="icon" href="../assets/icons/icon.svg" type="image/svg+xml">')
    w('<link rel="apple-touch-icon" href="../assets/icons/apple-touch-icon.png">')
    w('<link rel="stylesheet" href="../assets/css/app.css">')
    w('<script src="../assets/js/theme.js"></script>')
    w('<script src="../assets/js/common.js" defer></script>')
    w("<style>%s</style>" % PAGE_CSS)
    w("<script>%s</script>" % PAGE_JS)
    w("</head>")
    w("<body>")
    w('<a class="skip-link" href="#main">Skip to content</a>')
    w('<header class="app-header">\n'
      '  <a class="hdr-btn" href="../index.html" aria-label="Back to hub"><svg viewBox="0 0 24 24" aria-hidden="true">'
      '<path d="M15 18l-6-6 6-6"/></svg><span>Hub</span></a>\n'
      "  <h1>Emergency Guide &amp; Scenarios</h1>\n"
      '  <span class="net-dot" role="img"></span>\n'
      '  <button class="hdr-btn" type="button" data-theme-toggle></button>\n'
      "</header>")
    w('<main id="main" class="page">')
    w('<p class="lead">Step-by-step responses for %d emergencies, plus reference cards for water, signalling, '
      "Morse code, knots and first aid. Print the PDF and keep it in your go-bag and car — "
      "it works with no phone, no power and no signal.</p>" % len(C.SCENARIOS))
    w('<div class="callout danger"><strong class="callout-title">Life in danger?</strong><p>%s</p></div>'
      % html_markup(C.CALL_HELP))
    w('<div class="row no-print pdf-actions">\n'
      '  <a class="btn primary" href="%s" target="_blank" rel="noopener">Open the PDF</a>\n'
      '  <a class="btn" href="%s" download="%s">Download PDF</a>\n'
      '  <button class="btn print-btn" type="button" data-print>Print this page</button>\n'
      '  <button class="btn" type="button" data-expand-all="#main">Expand all</button>\n'
      "</div>" % (C.PDF_FILENAME, C.PDF_FILENAME, C.PDF_FILENAME))
    w('<p class="pdf-note no-print">PDF: %d pages, US Letter (also fits A4), black-and-white friendly, %s. '
      "On some phones the PDF opens in a separate viewer app or simply downloads — the HTML version below "
      "has the same content.</p>" % (total_pages, size_txt))
    w('<p class="disclaimer">%s</p>' % html_markup(C.DISCLAIMER_SHORT))

    toc = [("priorities", "Priorities"), ("scenarios", "Scenarios"), ("water", "Water"),
           ("signals", "Signalling"), ("morse", "Morse code"), ("knots", "Knots"),
           ("firstaid", "First aid"), ("fill-in", "Fill-in pages"), ("how-to-use", "How to use")]
    w('<nav class="toc" aria-label="On this page"><ul>%s</ul></nav>'
      % "".join('<li><a href="#%s">%s</a></li>' % (k, esc(t)) for k, t in toc))

    # ---- priorities
    w('<section id="priorities">')
    w("<h2>Priorities: STOP, rule of 3s, order</h2>")
    w("<h3>1. STOP</h3>")
    w('<div class="table-wrap"><table class="data"><tbody>')
    for letter_, word, text in C.STOP:
        w('<tr><td class="stop-letter">%s</td><td><strong>%s</strong> — %s</td></tr>'
          % (esc(letter_), esc(word), html_markup(text)))
    w("</tbody></table></div>")
    w("<h3>2. Rule of 3s — you can survive about:</h3>")
    w('<div class="table-wrap"><table class="data"><tbody>')
    for a, b in C.RULE_OF_3S:
        w('<tr><td class="k">%s</td><td>%s</td></tr>' % (esc(a), esc(b)))
    w("</tbody></table></div>")
    w('<p class="muted">%s</p>' % esc(C.RULE_OF_3S_NOTE))
    w("<h3>3. In this order</h3>")
    w(ol_steps(["**%s** — %s" % (a, b) for a, b in C.PRIORITY_ORDER]))
    w(callout_html("info", "", C.PRIORITY_NOTE))
    w("</section>")

    # ---- scenarios
    w('<section id="scenarios" class="pb">')
    w("<h2>Scenarios</h2>")
    w('<p>Tap a scenario to open it. Each has numbered steps, what <strong>not</strong> to do, and what to have ready.</p>')
    w('<ol class="sc-index">%s</ol>'
      % "".join('<li><a href="#%s">%s</a></li>' % (sc["id"], esc(sc["title"])) for sc in C.SCENARIOS))
    for i, sc in enumerate(C.SCENARIOS, start=1):
        w('<details class="item" id="%s">' % sc["id"])
        w('<summary>%d. %s <span class="sub">%s</span></summary>' % (i, esc(sc["title"]), html_markup(sc["sub"])))
        w('<div class="body">')
        w('<div class="callout ok"><strong class="callout-title">Remember</strong><p>%s</p></div>'
          % html_markup(sc["key"]))
        w("<h3>Step by step</h3>")
        w(ol_steps(sc["steps"]))
        for kind, title, text in sc.get("callouts", []):
            w(callout_html(kind, title, text))
        w('<div class="lists-2">')
        w("<div><h3>Do NOT</h3>%s</div>" % ul(sc["dont"], "dont"))
        w("<div><h3>Have ready</h3>%s</div>" % ul(sc["ready"], "ready"))
        w("</div>")
        w("</div></details>")
    w("</section>")

    # ---- water
    W = C.WATER
    w('<section id="water" class="pb">')
    w("<h2>Water purification</h2>")
    w("<p>%s</p>" % html_markup(W["intro"]))
    w('<div class="table-wrap"><table class="data stack"><thead><tr><th scope="col">Method</th><th scope="col">How</th>'
      '<th scope="col">Works against / limits</th></tr></thead><tbody>')
    for m, how, lim in W["methods"]:
        w('<tr><th scope="row">%s</th><td data-label="How">%s</td><td data-label="Limits">%s</td></tr>'
          % (esc(m), html_markup(how), html_markup(lim)))
    w("</tbody></table></div>")
    w("<h3>Bleach dose (CDC)</h3>")
    w('<div class="table-wrap"><table class="data"><thead><tr>%s</tr></thead><tbody>'
      % "".join('<th scope="col">%s</th>' % esc(h) for h in W["bleach_head"]))
    for a, b, c in W["bleach"]:
        w('<tr><th scope="row">%s</th><td><strong>%s</strong></td><td><strong>%s</strong></td></tr>'
          % (esc(a), esc(b), esc(c)))
    w("</tbody></table></div>")
    w(ul(W["bleach_notes"]))
    for kind, title, text in W["callouts"]:
        w(callout_html(kind, title, text))
    w('<p>More detail: <a href="../water/index.html">Water page</a>.</p>')
    w("</section>")

    # ---- signals
    w('<section id="signals" class="pb">')
    w("<h2>Signalling</h2>")
    w("<h3>Ground-to-air emergency code (ICAO)</h3>")
    w('<div class="table-wrap"><table class="data g2a"><thead><tr><th scope="col">Lay out</th>'
      '<th scope="col">Symbol</th><th scope="col">Meaning</th></tr></thead><tbody>')
    for k, m in C.GROUND_TO_AIR:
        name = "Arrow" if k == "ARROW" else k
        w('<tr><td class="sym">%s</td><td class="letter">%s</td><td>%s</td></tr>'
          % (g2a_svg(k, "%s symbol" % name), name, esc(m)))
    w("</tbody></table></div>")
    w(ul(C.GROUND_TO_AIR_NOTES))
    w("<p>%s</p>" % html_markup(C.BODY_SIGNALS))
    w(callout_html("info", "Distress", C.DISTRESS_THREES))
    w("<h3>Whistle</h3>")
    w(ul(C.WHISTLE))
    w("<h3>Light: SOS</h3>")
    w(ul(C.LIGHT_SOS))
    w("<h3>Signal mirror</h3>")
    w(ol_steps(C.MIRROR_STEPS))
    w("<h3>Phone, beacon and radio</h3>")
    w(ul(C.PHONE_RADIO))
    w("</section>")

    # ---- morse
    w('<section id="morse">')
    w("<h2>Morse code</h2>")
    half = (len(C.MORSE) + 1) // 2
    w('<div class="table-wrap"><table class="data morse"><thead><tr><th scope="col">Char</th><th scope="col">Code</th>'
      '<th scope="col">Char</th><th scope="col">Code</th></tr></thead><tbody>')
    for r in range(half):
        cells = []
        for idx in (r, r + half):
            if idx < len(C.MORSE):
                ch, code = C.MORSE[idx]
                cells.append('<th scope="row" class="ch">%s</th><td class="mc">%s</td>' % (ch, morse_html(code)))
            else:
                cells.append("<td></td><td></td>")
        w("<tr>%s</tr>" % "".join(cells))
    w("</tbody></table></div>")
    w("<p>%s</p>" % html_markup(C.MORSE_NOTE))
    w("</section>")

    # ---- knots
    w('<section id="knots" class="pb">')
    w("<h2>Knots</h2>")
    w("<p>%s</p>" % html_markup(C.KNOTS_NOTE))
    for k in C.KNOTS:
        w('<details class="item" id="%s">' % k["id"])
        w('<summary>%s <span class="sub">%s</span></summary>' % (esc(k["name"]), html_markup(k["use"])))
        w('<div class="body">')
        w(ol_steps(k["steps"]))
        w(callout_html("warn", "", k["caution"]))
        w("</div></details>")
    w("</section>")

    # ---- first aid
    w('<section id="firstaid" class="pb">')
    w("<h2>First-aid quick steps</h2>")
    w("<p>Call 911 / 112 early. Protect yourself first. These are reminders — take a hands-on course. "
      'More detail: <a href="../firstaid/index.html">First Aid page</a>.</p>')
    for fa in C.FIRST_AID:
        w('<details class="item" id="%s">' % fa["id"])
        w("<summary>%s</summary>" % esc(fa["title"]))
        w('<div class="body">')
        w(ol_steps(fa["steps"]))
        if fa.get("note"):
            w("<p>%s</p>" % html_markup(fa["note"]))
        w("</div></details>")
    w(callout_html("info", "Medicines", C.OTC_MEDS))
    w("</section>")

    # ---- fill-in
    w('<section id="fill-in">')
    w("<h2>Fill-in pages (in the PDF)</h2>")
    w("<p>The printed PDF has a <strong>fill-in box on page 1</strong> (name, date of birth, blood type, allergies, "
      "medications, conditions, emergency contacts) and a <strong>ruled page %d</strong> for ICE contacts, meeting "
      "points and waypoints. Fill them in by hand in pencil or waterproof pen. In the app, you can also save "
      'waypoints on the <a href="../map/index.html">Map page</a>.</p>' % PAGES.get("contacts", 0))
    w("</section>")

    # ---- how to use
    w('<section id="how-to-use">')
    w("<h2>How to use this guide</h2>")
    w(ol_steps(C.HOW_TO_USE))
    w('<div class="disclaimer"><strong>Disclaimer.</strong> %s</div>' % html_markup(C.DISCLAIMER))
    w('<p class="muted">%s</p>' % html_markup(C.SOURCES))
    w("</section>")

    w('<footer class="page-foot">%s — %s (%s). Not a substitute for training or professional care. '
      'Related: <a href="../firstaid/index.html">First aid</a> · <a href="../water/index.html">Water</a> · '
      '<a href="../fireshelter/index.html">Fire &amp; shelter</a> · <a href="../map/index.html">Map</a> · '
      '<a href="../index.html">Hub</a></footer>'
      % (esc(C.APP_NAME), esc(C.DOC_TITLE), esc(C.EDITION)))
    w("</main>")
    w("</body>")
    w("</html>")
    doc = "\n".join(out) + "\n"

    # every in-page reference must resolve
    ids = set(re.findall(r'\sid="([^"]+)"', doc))
    hrefs = set(re.findall(r'href="#([^"]+)"', doc))
    missing = sorted(hrefs - ids)
    if missing:
        raise SystemExit("HTML links to missing ids: %s" % ", ".join(missing))
    dup = [i for i in ids if len(re.findall(r'\sid="%s"' % re.escape(i), doc)) > 1]
    if dup:
        raise SystemExit("Duplicate HTML ids: %s" % ", ".join(dup))
    with open(HTML_PATH, "w", encoding="utf-8") as f:
        f.write(doc)
    return len(doc.encode("utf-8"))


def main():
    total, passes = build_pdf()
    pdf_size = os.path.getsize(PDF_PATH)
    html_size = build_html(total)
    print("PDF : %s  (%d pages, %d bytes, %d build passes)" % (os.path.relpath(PDF_PATH, APP_ROOT), total,
                                                               pdf_size, passes))
    print("HTML: %s  (%d bytes)" % (os.path.relpath(HTML_PATH, APP_ROOT), html_size))
    print("Index: " + ", ".join("%s=p%d" % (k, PAGES[k]) for k, _ in INDEX_ENTRIES[0] + INDEX_ENTRIES[1]))


if __name__ == "__main__":
    main()
