"""Convert the Markdown policies in data/policies into PDFs in data/policies_pdf."""
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

SRC = Path("data/policies")
OUT = Path("data/policies_pdf")
OUT.mkdir(parents=True, exist_ok=True)

META_FIELDS = [
    ("Document ID", "document_id"),
    ("Category", "category"),
    ("Version", "version"),
    ("Language", "language"),
    ("Source", "source"),
    ("Created", "created_at"),
    ("Updated", "updated_at"),
]

styles = getSampleStyleSheet()
title_style = ParagraphStyle("PolTitle", parent=styles["Title"], fontSize=20, spaceAfter=8)
meta_style = ParagraphStyle("PolMeta", parent=styles["Normal"], fontSize=9, leading=12,
                            textColor=colors.HexColor("#444444"))
note_style = ParagraphStyle("PolNote", parent=styles["Italic"], fontSize=10,
                            spaceBefore=8, spaceAfter=8)
h2_style = ParagraphStyle("PolH2", parent=styles["Heading2"], spaceBefore=12, spaceAfter=4)
body_style = ParagraphStyle("PolBody", parent=styles["BodyText"], fontSize=10.5,
                            leading=14, spaceAfter=3)


def parse(path):
    """Split a policy file into its metadata header and its body lines."""
    text = path.read_text(encoding="utf-8")
    _, header, body = text.split("---", 2)
    meta = {}
    for line in header.strip().splitlines():
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip()
    return meta, body.strip().splitlines()


def make_footer(meta):
    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.drawString(2 * cm, 1.2 * cm,
                          f"{meta['document_id']} v{meta['version']} - SIMULATED capstone policy")
        canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f"Page {doc.page}")
        canvas.restoreState()
    return footer


for md_file in sorted(SRC.glob("*.md")):
    meta, lines = parse(md_file)
    story = []

    for line in lines:
        line = line.rstrip()
        if not line:
            continue
        if line.startswith("# "):
            story.append(Paragraph(escape(line[2:]), title_style))
            for label, key in META_FIELDS:
                story.append(Paragraph(f"{label}: {escape(meta[key])}", meta_style))
            story.append(Spacer(1, 6))
        elif line.startswith("> "):
            story.append(Paragraph(escape(line[2:]), note_style))
        elif line.startswith("## "):
            story.append(Paragraph(escape(line[3:]), h2_style))
        else:
            story.append(Paragraph(escape(line), body_style))

    pdf_path = OUT / f"{md_file.stem}.pdf"
    doc = SimpleDocTemplate(
        str(pdf_path), pagesize=A4, title=meta["title"], author="Capstone team",
        leftMargin=2 * cm, rightMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm,
    )
    footer = make_footer(meta)
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"{pdf_path.name}: {doc.page} page(s)")