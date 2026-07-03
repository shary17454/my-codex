from __future__ import annotations

from pathlib import Path

from pypdf import PdfReader, PdfWriter


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "output" / "pdf" / "patrol_iab_merged"
OUT = ROOT / "output" / "pdf" / "patrol_iab_merged_master.pdf"


def main() -> None:
    files = sorted(SRC.glob("*.pdf"))
    writer = PdfWriter()
    total_pages = 0
    for file in files:
        reader = PdfReader(str(file))
        writer.append(reader, outline_item=file.stem)
        total_pages += len(reader.pages)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("wb") as handle:
        writer.write(handle)
    print({"files": len(files), "pages": total_pages, "output": str(OUT), "bytes": OUT.stat().st_size})


if __name__ == "__main__":
    main()
