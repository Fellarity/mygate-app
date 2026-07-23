import json
import requests
import sys

supabase_url = 'https://rmvidmvgwtrqhwbnoyku.supabase.co/rest/v1/users'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtdmlkbXZnd3RycWh3Ym5veWt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzQxMzQsImV4cCI6MjEwMDIxMDEzNH0.0UBbsuNPZJrwovG1CJUwSYvmGWwA2i3btp28rbK1G9w'

with open('users_to_insert.json', 'r') as f:
    users = json.load(f)

# Deduplicate by employee_code
unique_users = {}
for u in users:
    # Prefer Team Leader role if duplicates exist
    if u['employee_code'] not in unique_users or u['role'] == 'Team Leader':
        unique_users[u['employee_code']] = u
        
users = list(unique_users.values())

headers = {
    'apikey': anon_key,
    'Authorization': f'Bearer {anon_key}',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates'
}

batch_size = 100
for i in range(0, len(users), batch_size):
    batch = users[i:i+batch_size]
    response = requests.post(
        f'{supabase_url}?on_conflict=employee_code',
        headers=headers,
        json=batch
    )
    if response.status_code >= 300:
        print(f"Error inserting batch {i//batch_size}:", response.status_code, response.text)
        sys.exit(1)
    else:
        print(f"Successfully inserted batch {i//batch_size} ({len(batch)} records)")

print("All users upserted successfully!")
