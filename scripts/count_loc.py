import os
import sys

dirs = ['Cambium', 'OpenClaw', 'Phteah-pi', 'AutoCAD-AHK', 'FileOrganizer']
exts = {'.cs', '.ts', '.tsx', '.js', '.jsx', '.py', '.sql', '.html', '.css', '.json'}

total = 0
for d in dirs:
    d_total = 0
    if os.path.exists(d):
        for root, _, files in os.walk(d):
            # Skip common build/dependency directories
            if any(skip in root.replace('\\', '/') for skip in ['/node_modules', '/.git', '/bin/', '/obj/', '/dist/', '/out/']):
                continue
            for f in files:
                if any(f.endswith(ext) for ext in exts):
                    try:
                        with open(os.path.join(root, f), 'r', encoding='utf-8', errors='ignore') as file:
                            lines = sum(1 for _ in file)
                            d_total += lines
                            total += lines
                    except Exception as e:
                        pass
        print(f"{d} line count: {d_total}")
print(f"Total line count: {total}")
