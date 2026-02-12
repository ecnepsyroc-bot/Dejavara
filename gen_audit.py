import json

html = '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Laminate Audit</title>
<style>
body{font-family:Arial;font-size:10pt;padding:20px}
h1{text-align:center;font-size:16pt}
h2{background:#333;color:white;padding:5px 10px;font-size:12pt}
table{width:100%;border-collapse:collapse;margin-bottom:15px}
th,td{border:1px solid #ccc;padding:6px 4px}
th{background:#eee;font-size:9pt}
.blank{background:#fffde7;min-height:20px}
.actual{background:#e3f2fd;min-height:20px}
.qty{font-weight:bold;text-align:center}
</style></head><body>
<h1>LAMINATE INVENTORY AUDIT SHEET</h1>
<p style="text-align:center">Original Count: July 24, 2025 | Audit Date: _______________</p>
<p><b>Instructions:</b> Fill YELLOW cells with missing data. Record actual count in BLUE cells.</p>
'''

data = json.load(open(r'C:\Dev\Dejavara\laminate-inventory.json'))
items = data['items']
categories = {}
for item in items:
    cat = item.get('category', 'OTHER')
    if cat not in categories:
        categories[cat] = []
    categories[cat].append(item)

for cat, items in categories.items():
    html += f'<h2>{cat}</h2>\n<table>\n'
    html += '<tr><th>Name</th><th>Code</th><th>Finish</th><th>Size</th><th>Mfr</th><th>Location</th><th>Doc Qty</th><th>Actual</th><th>OK?</th></tr>\n'
    for item in items:
        name = item.get('name', '')
        code = item.get('code', '')
        finish = item.get('finish', '')
        size = item.get('size', '')
        qty = item.get('qty', 0)
        code_cell = f'<td>{code}</td>' if code else '<td class="blank"></td>'
        finish_cell = f'<td>{finish}</td>' if finish else '<td class="blank"></td>'
        html += f'<tr><td>{name}</td>{code_cell}{finish_cell}<td>{size}</td><td class="blank"></td><td class="blank"></td><td class="qty">{qty}</td><td class="actual"></td><td></td></tr>\n'
    html += '</table>\n'

html += '<p><b>Note:</b> LOTS OF UNMARKED LAM. and SMALLER OFFCUTS IN RACK #</p>\n'
html += '<p>Audited By: _______________ | Signature: _______________ | Date: _______________</p>\n'
html += '</body></html>'

with open(r'C:\Dev\Dejavara\laminate-audit-sheet.html', 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Created audit sheet with {sum(len(v) for v in categories.values())} items')
