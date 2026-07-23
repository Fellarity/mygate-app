import pandas as pd
import json

file_path = 'csv/EMPLOYEE EMAIL MASTER_18-06-2026_UPDATED.xlsx'
df = pd.read_excel(file_path)
print("Columns:", list(df.columns))
print(df.head(5).to_dict(orient='records'))
print("Total rows:", len(df))
