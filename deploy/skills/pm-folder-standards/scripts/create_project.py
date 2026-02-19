#!/usr/bin/env python3
"""Create a new Cambium project folder structure (00-11 scheme)."""

import argparse
import os
import sys

TEMPLATE = {
    "00-contract": [
        "addenda", "agreement", "drawings", "ifc", "ift",
        "insurance", "scope", "specifications"
    ],
    "01-admin": [
        "certs", "change-order", "closeout", "correspondence",
        "meeting-minutes", "rfi", "schedule", "site-instruction",
        "submittal", "transmittal"
    ],
    "02-financial": ["budget", "invoice", "progress-claim"],
    "03-cad": ["working", "archive", "library"],
    "04-drawings": [
        "approved", "buyout", "ifc", "install", "production", "revision"
    ],
    "05-materials": [
        "finish", "hardware", "spec"
    ],
    "06-samples": [
        "finish", "glass", "hardware", "laminate", "stone", "veneer"
    ],
    "07-production": [],
    "08-buyout": [],
    "09-coordination": ["doors", "electrical", "glazing", "mechanical"],
    "10-site": ["measure", "photo"],
    "11-awmac": ["submissions", "qc", "_source", "_received", "_template"],
    "_archive": [],
    "_cambium": ["cache"],
}

# Underscore subfolders within certain paths
UNDERSCORE_SUBS = {
    "01-admin/rfi": ["_received", "_template"],
    "01-admin/submittal": ["_source", "_template"],
    "08-buyout": ["_received"],
    "09-coordination/doors": ["_received", "_source"],
}


def create_project(base_path: str, job_name: str, dry_run: bool = True):
    project_dir = os.path.join(base_path, job_name)
    created = []

    # Top-level folders and their children
    for folder, subfolders in TEMPLATE.items():
        folder_path = os.path.join(project_dir, folder)
        created.append(folder_path)
        for sub in subfolders:
            created.append(os.path.join(folder_path, sub))

    # Underscore subfolders
    for parent, subs in UNDERSCORE_SUBS.items():
        for sub in subs:
            created.append(os.path.join(project_dir, parent, sub))

    if dry_run:
        print(f"DRY RUN - would create {len(created)} folders under {project_dir}:\n")
        for p in sorted(created):
            rel = os.path.relpath(p, project_dir)
            print(f"  {rel}/")
        print(f"\nRun with --execute to create.")
    else:
        for p in sorted(created):
            os.makedirs(p, exist_ok=True)
        print(f"Created {len(created)} folders under {project_dir}")

    return created


def main():
    parser = argparse.ArgumentParser(description="Create Cambium project structure")
    parser.add_argument("name", help="Project folder name (e.g., 2601-netflix-burbank)")
    parser.add_argument(
        "--base", default=r"C:\Projects",
        help="Base directory for projects (default: C:\\Projects)"
    )
    parser.add_argument(
        "--execute", action="store_true",
        help="Actually create folders (default is dry-run)"
    )
    args = parser.parse_args()

    create_project(args.base, args.name, dry_run=not args.execute)


if __name__ == "__main__":
    main()
