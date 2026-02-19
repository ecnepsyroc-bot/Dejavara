#!/usr/bin/env python3
"""
Migrate a legacy Feature Millwork project into Cambium 00-11 structure.

- Dry-run by default (--execute to copy)
- Copies, never moves
- Flags ambiguous files for manual triage
- Skips junk (Thumbs.db, .DS_Store, desktop.ini, *.bak in root)
"""

import argparse
import os
import shutil
import sys
from pathlib import Path

# ── Folder mapping: legacy name (uppercased for matching) → Cambium path ──

FOLDER_MAP = {
    # Factory Orders / Production
    "FO": "07-production",
    "FOS": "07-production",
    "FACTORY_ORDER": "07-production",
    "PDF SHOP DWG": "04-drawings/production",
    "PDFS": "04-drawings/production",
    "SHOPS": "04-drawings/production",
    "REVIEWED SHOP DWG": "04-drawings/approved",
    "REVIWED SHOP DWG": "04-drawings/approved",
    "REVIEWED": "04-drawings/approved",
    "APPROVEDF DWG & SAMPLES": "04-drawings/approved",
    "IFC": "04-drawings/ifc",
    "IFT": "04-drawings/ifc",

    # Administration
    "PO": "08-buyout",
    "POS": "08-buyout",
    "PURCHASE_ORDER": "08-buyout",
    "TRANSMITTAL": "01-admin/transmittal",
    "TRANSMITTALS": "01-admin/transmittal",
    "RFI": "01-admin/rfi",
    "RFIS": "01-admin/rfi",
    "REQUEST_FOR_INFORMATION": "01-admin/rfi",
    "SI": "01-admin/site-instruction",
    "CCN": "01-admin/change-order",
    "CCNS": "01-admin/change-order",
    "PCN": "01-admin/change-order",
    "PCNS": "01-admin/change-order",
    "SAMPLES": "06-samples",

    # Contract / Specs
    "SPEC": "00-contract/specifications",
    "SPECS": "00-contract/specifications",
    "CONTRACT DUCUMENT": "00-contract",
    "CONTRACT DOCUMENT": "00-contract",
    "CONTRACTOR_DOCS_RECEIVED": "00-contract",
    "ARCHITECTURALS": "00-contract/drawings",

    # Site
    "SITE MEASURE": "10-site/measure",
    "SITE MEASURES": "10-site/measure",
    "SITE_MEASURE": "10-site/measure",
    "SITE MEASUER": "10-site/measure",
    "SITE MEASUERMENT": "10-site/measure",
    "SITE PICTURE": "10-site/photo",
    "SITE PICTURES": "10-site/photo",

    # Misc known
    "SCHEDULE": "01-admin/schedule",
    "MEETING MINUTES": "01-admin/meeting-minutes",
}

# Extensions to route when found loose at project root
ROOT_FILE_ROUTES = {
    ".dwg": "03-cad/working",
    ".dxf": "03-cad/working",
}

JUNK_FILES = {"thumbs.db", ".ds_store", "desktop.ini"}
JUNK_EXTENSIONS = {".bak", ".tmp", ".log"}


def classify_folder(name: str) -> str | None:
    """Map a legacy folder name to its Cambium equivalent."""
    upper = name.upper().strip()
    return FOLDER_MAP.get(upper)


def classify_root_file(filename: str) -> str | None:
    """Route loose root-level files by extension."""
    ext = Path(filename).suffix.lower()
    return ROOT_FILE_ROUTES.get(ext)


def is_junk(filename: str) -> bool:
    """Check if a file is junk that should be skipped."""
    lower = filename.lower()
    if lower in JUNK_FILES:
        return True
    ext = Path(filename).suffix.lower()
    return ext in JUNK_EXTENSIONS


def scan_project(source_dir: str):
    """Scan a legacy project and classify all contents."""
    source = Path(source_dir)
    results = {"mapped": [], "triage": [], "junk": []}

    for item in sorted(source.iterdir()):
        if item.is_dir():
            # Skip hidden/system folders
            if item.name.startswith(".") or item.name.startswith("_"):
                continue

            dest = classify_folder(item.name)
            if dest:
                # Count files recursively
                file_count = sum(1 for _ in item.rglob("*") if _.is_file())
                results["mapped"].append({
                    "source": item.name,
                    "dest": dest,
                    "files": file_count,
                })
            else:
                file_count = sum(1 for _ in item.rglob("*") if _.is_file())
                results["triage"].append({
                    "source": item.name,
                    "files": file_count,
                    "reason": "Unknown folder — needs manual classification",
                })

        elif item.is_file():
            if is_junk(item.name):
                results["junk"].append(item.name)
            else:
                dest = classify_root_file(item.name)
                if dest:
                    results["mapped"].append({
                        "source": item.name,
                        "dest": dest,
                        "files": 1,
                    })
                else:
                    results["triage"].append({
                        "source": item.name,
                        "files": 1,
                        "reason": "Root file — unknown type",
                    })

    return results


def print_report(source_dir: str, results: dict):
    """Print a human-readable migration report."""
    total_mapped = sum(r["files"] for r in results["mapped"])
    total_triage = sum(r["files"] for r in results["triage"])
    total_junk = len(results["junk"])
    total = total_mapped + total_triage + total_junk

    print(f"\n{'='*60}")
    print(f"MIGRATION REPORT: {Path(source_dir).name}")
    print(f"{'='*60}")
    print(f"Total items: {total}")
    print(f"  Auto-mapped: {total_mapped}")
    print(f"  Needs triage: {total_triage}")
    print(f"  Junk (skip): {total_junk}")
    print(f"  Coverage: {total_mapped/(total - total_junk)*100:.0f}%" if (total - total_junk) > 0 else "")

    if results["mapped"]:
        print(f"\n--- AUTO-MAPPED ({total_mapped} files) ---")
        for r in results["mapped"]:
            print(f"  {r['source']:30s} -> {r['dest']:30s} ({r['files']} files)")

    if results["triage"]:
        print(f"\n--- NEEDS TRIAGE ({total_triage} files) ---")
        for r in results["triage"]:
            print(f"  {r['source']:30s}    {r['reason']} ({r['files']} files)")

    if results["junk"]:
        print(f"\n--- JUNK (skip) ---")
        for name in results["junk"]:
            print(f"  {name}")

    print()


def execute_migration(source_dir: str, dest_dir: str, results: dict):
    """Copy mapped files from source to Cambium structure."""
    source = Path(source_dir)
    dest = Path(dest_dir)

    copied = 0
    for r in results["mapped"]:
        src_path = source / r["source"]
        dst_base = dest / r["dest"]

        if src_path.is_dir():
            for f in src_path.rglob("*"):
                if f.is_file() and not is_junk(f.name):
                    rel = f.relative_to(src_path)
                    dst_file = dst_base / rel
                    dst_file.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(f, dst_file)
                    copied += 1
        elif src_path.is_file():
            dst_base.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_base / src_path.name)
            copied += 1

    print(f"Copied {copied} files to {dest_dir}")
    return copied


def main():
    parser = argparse.ArgumentParser(
        description="Migrate legacy Feature Millwork project to Cambium structure"
    )
    parser.add_argument("source", help="Path to legacy project folder")
    parser.add_argument(
        "--dest",
        help="Destination path for Cambium structure (default: {source}-cambium/)",
    )
    parser.add_argument(
        "--execute", action="store_true",
        help="Actually copy files (default is dry-run report only)"
    )
    args = parser.parse_args()

    if not os.path.isdir(args.source):
        print(f"Error: {args.source} is not a directory")
        sys.exit(1)

    dest = args.dest or f"{args.source.rstrip(os.sep)}-cambium"

    results = scan_project(args.source)
    print_report(args.source, results)

    if args.execute:
        if results["triage"]:
            print(f"WARNING: {len(results['triage'])} items need manual triage.")
            print("Only auto-mapped items will be copied.\n")
        execute_migration(args.source, dest, results)
    else:
        print("DRY RUN — run with --execute to copy files.")


if __name__ == "__main__":
    main()
