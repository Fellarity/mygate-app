import json
import csv

with open('csv/hierarchy_structure.json', 'r', encoding='utf-8') as f:
    hierarchy = json.load(f)

# Extract from JSON
json_users = {}
def traverse(node, manager_email=None):
    email = node.get('email')
    if email:
        json_users[email] = {
            'name': node.get('name'),
            'designation': node.get('designation'),
            'manager_email': manager_email
        }
        for r in node.get('reports', []):
            traverse(r, email)

for root in hierarchy:
    traverse(root)

print(f"Total people in JSON: {len(json_users)}")

# Extract from CSV
csv_users = {}
try:
    with open('csv/Daily Working(Sheet1).csv', 'r', encoding='latin1') as f:
        reader = csv.DictReader(f)
        for row in reader:
            emp_name = row.get('Emp Name', '').strip()
            emp_code = row.get('Emp Code', '').strip()
            tl_name = row.get('Team Leader', '').strip()
            dept = row.get('Department', '').strip()
            contact = row.get('Contact No.', '').strip()
            if emp_name and emp_code:
                csv_users[emp_name.lower()] = {
                    'code': emp_code,
                    'name': emp_name,
                    'department': dept,
                    'contact': contact,
                    'tl_name': tl_name
                }
except Exception as e:
    print(e)

print(f"Total unique employees in CSV: {len(csv_users)}")

# Match JSON and CSV
matched = 0
unmatched_json = []
for email, data in json_users.items():
    name_lower = data['name'].strip().lower() if data['name'] else ''
    if name_lower in csv_users:
        matched += 1
    else:
        # try partial match
        found = False
        for cname in csv_users:
            if name_lower in cname or cname in name_lower:
                matched += 1
                found = True
                break
        if not found:
            unmatched_json.append(data['name'])

print(f"Matched JSON users with CSV: {matched}")
print(f"Some unmatched JSON users: {unmatched_json[:5]}")

