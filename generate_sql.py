import json
import pandas as pd

json_file = 'csv/hierarchy_structure.json'
excel_file = 'csv/EMPLOYEE EMAIL MASTER_18-06-2026_UPDATED.xlsx'
output_json = 'users_to_insert.json'

with open(json_file, 'r', encoding='utf-8') as f:
    hierarchy = json.load(f)

df = pd.read_excel(excel_file)
excel_map = {}
for idx, row in df.iterrows():
    email = str(row.get('Emplyoee Email id.', '')).strip().lower()
    if email and email != 'nan':
        excel_map[email] = {
            'employee_code': str(row.get('EmpNo', '')).strip(),
            'name': str(row.get('Name', '')).strip(),
            'department': str(row.get('CostCentre', '')).strip(),
        }

users_to_insert = []
generated_counter = 1

def traverse(node, manager_code):
    global generated_counter
    email = str(node.get('email', '')).strip().lower()
    if not email or email == 'none' or email == 'nan':
        return

    emp_code = ''
    department = ''
    
    excel_info = excel_map.get(email)
    if excel_info and excel_info['employee_code'] and excel_info['employee_code'] != 'nan':
        emp_code = excel_info['employee_code']
        department = excel_info['department'] if excel_info['department'] != 'nan' else ''
    else:
        emp_code = f"FA-GEN-{str(generated_counter).zfill(3)}"
        generated_counter += 1

    reports = node.get('reports', [])
    role = 'Team Leader' if len(reports) > 0 else 'Employee'
    name = str(node.get('name', 'Unknown'))
    if name == 'None' or name == 'nan':
        name = 'Unknown'
    designation = str(node.get('designation', ''))
    if designation == 'None' or designation == 'nan':
        designation = ''
    
    users_to_insert.append({
        'name': name,
        'email': email,
        'employee_code': emp_code,
        'password': 'pass123',
        'role': role,
        'designation': designation,
        'department': department,
        'team_leader': str(manager_code) if manager_code else None
    })

    for r in reports:
        traverse(r, emp_code)

for root in hierarchy:
    traverse(root, None)

with open(output_json, 'w') as f:
    json.dump(users_to_insert, f, indent=2)
    
print(f"Generated {len(users_to_insert)} records in {output_json}")
