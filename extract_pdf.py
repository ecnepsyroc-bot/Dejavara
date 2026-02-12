import fitz
import os

pdf_path = r"C:\Dev\Dejavara\laminate-inventory-scan.pdf"
img_path = r"C:\Dev\Dejavara\laminate-scan-page"

doc = fitz.open(pdf_path)
print(f"Pages: {len(doc)}")

for i, page in enumerate(doc):
    text = page.get_text().strip()
    print(f"--- Page {i+1} ---")
    if text:
        print(text[:1500])
    else:
        print("(scanned image - extracting...)")
        pix = page.get_pixmap(dpi=150)
        pix.save(f"{img_path}-{i+1}.png")
        print(f"Saved: {img_path}-{i+1}.png")
