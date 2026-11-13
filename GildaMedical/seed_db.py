"""
Seed script — loads cleaned_inventory.csv into the SQLite DB.
Run once: python seed_db.py
"""
import sqlite3, os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), 'instance', 'gilda_medical.db')
CSV_PATH = os.path.join(os.path.dirname(__file__), '..', 'cleaned_inventory.csv')

os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

try:
    import pandas as pd
    df = pd.read_csv(CSV_PATH)
    if 'is_expired' in df.columns:
        df = df[df['is_expired'] == False]
    df = df  # load all records
    use_pandas = True
except ImportError:
    use_pandas = False
    print("pandas not available — loading sample medicines instead")

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Check if already loaded
count = cursor.execute("SELECT COUNT(*) FROM medicine").fetchone()[0]
if count > 0:
    print(f"DB already has {count} medicines. Skipping seed.")
    conn.close()
    exit()

if use_pandas:
    loaded = 0
    for _, row in df.iterrows():
        try:
            cursor.execute('''
                INSERT INTO medicine (name, batch_no, expiry_date, supplier,
                    purchase_price, selling_price, quantity, company, packing, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                str(row.get('product', 'Unknown')),
                str(row.get('batch_no', '')),
                str(row.get('expiry_date', '')),
                str(row.get('company', '')),
                round(float(row.get('mrp', 0)) * 0.8, 2),
                float(row.get('mrp', 0)),
                max(int(row.get('qty', 10)), 1),
                str(row.get('company', '')),
                str(row.get('packing', '')),
                datetime.now()
            ))
            loaded += 1
        except Exception as e:
            continue
    conn.commit()
    print(f"✅ Loaded {loaded} medicines from CSV.")
else:
    # Fallback sample data
    samples = [
        ('Paracetamol 500mg', 'B001', '12/26', 'Sun Pharma', 8.0, 10.0, 100, 'Sun Pharma', '10x10'),
        ('Amoxicillin 250mg', 'B002', '06/26', 'Cipla', 40.0, 50.0, 80, 'Cipla', '10x10'),
        ('Metformin 500mg',   'B003', '03/27', 'Lupin', 24.0, 30.0, 60, 'Lupin', '10x10'),
        ('Atorvastatin 10mg', 'B004', '09/26', 'Ranbaxy', 32.0, 40.0, 50, 'Ranbaxy', '10x10'),
        ('Omeprazole 20mg',   'B005', '11/26', 'Dr Reddy', 16.0, 20.0, 90, 'Dr Reddy', '10x10'),
        ('Cetirizine 10mg',   'B006', '08/26', 'Mankind', 12.0, 15.0, 120, 'Mankind', '10x10'),
        ('Azithromycin 500mg','B007', '05/26', 'Cipla', 56.0, 70.0, 40, 'Cipla', '3x1'),
        ('Pantoprazole 40mg', 'B008', '07/26', 'Sun Pharma', 20.0, 25.0, 75, 'Sun Pharma', '10x10'),
        ('Ibuprofen 400mg',   'B009', '10/26', 'Abbott', 14.4, 18.0, 110, 'Abbott', '10x10'),
        ('Vitamin D3 60K',    'B010', '01/27', 'Mankind', 48.0, 60.0, 55, 'Mankind', '4x1'),
        ('Cough Syrup 100ml', 'B011', '04/26', 'Baidyanath', 60.0, 75.0, 30, 'Baidyanath', '1x100ml'),
        ('Insulin Glargine',  'B012', '02/26', 'Sanofi', 800.0, 1000.0, 8, 'Sanofi', '1x3ml'),
        ('Aspirin 75mg',      'B013', '12/26', 'Bayer', 8.0, 10.0, 200, 'Bayer', '10x10'),
        ('Losartan 50mg',     'B014', '06/27', 'Lupin', 28.0, 35.0, 65, 'Lupin', '10x10'),
        ('Dolo 650mg',        'B015', '09/26', 'Micro Labs', 20.0, 25.0, 150, 'Micro Labs', '15x1'),
    ]
    cursor.executemany('''
        INSERT INTO medicine (name, batch_no, expiry_date, supplier,
            purchase_price, selling_price, quantity, company, packing, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [(n,b,e,s,pp,sp,q,c,pk,datetime.now()) for n,b,e,s,pp,sp,q,c,pk in samples])
    conn.commit()
    print(f"✅ Loaded {len(samples)} sample medicines.")

conn.close()
