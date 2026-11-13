import pandas as pd
import sqlite3
from datetime import datetime

df = pd.read_csv('D:/Pharma_ai/cleaned_inventory.csv')
df = df[df['is_expired'] == False]  # load all non-expired items

conn = sqlite3.connect('D:/Pharma_ai/GildaMedical/instance/gilda_medical.db')
cursor = conn.cursor()

for _, row in df.iterrows():
    cursor.execute('''
        INSERT INTO medicine (name, batch_no, expiry_date, supplier, purchase_price, selling_price, quantity, company, packing, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        str(row['product']),
        str(row['batch_no']),
        str(row['expiry_date']),
        str(row['company']),
        round(float(row['mrp']) * 0.8, 2),  # purchase price = 80% of MRP
        float(row['mrp']),
        int(row['qty']) if row['qty'] > 0 else 10,
        str(row['company']),
        str(row['packing']),
        datetime.now()
    ))

conn.commit()
conn.close()
print(f"Loaded {len(df)} medicines into database.")
