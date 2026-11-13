"""Train all ML models needed by GildaMedical backend."""

import os
import pickle
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, r2_score

OUT = os.path.join(os.path.dirname(__file__), 'models')
os.makedirs(OUT, exist_ok=True)

np.random.seed(42)

print("\n Starting Model Training...\n")

# 1. Product catalog & label encoder


products = [
    'Paracetamol 500mg', 'Crocin 500mg', 'Dolo 650mg', 'Calpol 500mg',
    'Amoxicillin 250mg', 'Amoxicillin 500mg', 'Augmentin 625mg',
    'Ibuprofen 400mg', 'Brufen 400mg', 'Combiflam',
    'Cetirizine 10mg', 'Allegra 120mg', 'Montair LC',
    'Azithromycin 250mg', 'Azithromycin 500mg', 'Zithromax 500mg',
    'Metformin 500mg', 'Glycomet 500mg', 'Glucophage 500mg',
    'Atorvastatin 10mg', 'Lipitor 10mg', 'Rosuvastatin 10mg',
    'Omeprazole 20mg', 'Pantoprazole 40mg', 'Rabeprazole 20mg',
    'Amlodipine 5mg', 'Norvasc 5mg', 'Telmisartan 40mg',
    'Vitamin D3 60000IU', 'Calcirol 60000IU', 'Vitamin C 500mg',
]

companies = ['Sun Pharma', 'Cipla', 'Dr Reddys', 'Lupin', 'Mankind', 'Alkem']
packings  = ['10 Tab', '15 Tab', '30 Tab', '1 Strip', '60ml Syrup']

catalog = pd.DataFrame({
    'product': products,
    'company': [np.random.choice(companies) for _ in products],
    'packing': [np.random.choice(packings) for _ in products],
    'avg_mrp': np.round(np.random.uniform(20, 300, len(products)), 2),
})

catalog.to_csv(os.path.join(OUT, 'product_catalog.csv'), index=False)
print("✓ product_catalog.csv created")

le_product = LabelEncoder().fit(catalog['product'])
pickle.dump(le_product, open(os.path.join(OUT, 'product_label_encoder.pkl'), 'wb'))
print("✓ product_label_encoder.pkl saved")


# 2. Demand Forecast Model (Regression)

print("\nTraining Demand Forecast Model...")

n = 500

X_demand = np.column_stack([
    np.random.randint(0, len(products), n),
    np.random.randint(1, 13, n),
    np.random.randint(2023, 2026, n),
    np.random.uniform(20, 300, n),
    np.random.randint(1, 10, n),
])

y_demand = (X_demand[:, 0] * 5 + X_demand[:, 1] * 2 +
            np.random.normal(0, 10, n)).clip(10, 500)

X_train, X_test, y_train, y_test = train_test_split(
    X_demand, y_demand, test_size=0.2, random_state=42
)

demand_model = RandomForestRegressor(n_estimators=50, random_state=42)
demand_model.fit(X_train, y_train)

y_pred = demand_model.predict(X_test)

r2 = r2_score(y_test, y_pred)

print("Demand Forecast R2 Score:", round(r2, 3))

pickle.dump(demand_model, open(os.path.join(OUT, 'demand_forecast_model.pkl'), 'wb'))
print("✓ demand_forecast_model.pkl saved")


# 3. Expiry Risk Model (Classification)

print("\nTraining Expiry Risk Model...")

risk_labels = ['SAFE', 'MEDIUM_RISK', 'HIGH_RISK', 'EXPIRED']

le_risk = LabelEncoder().fit(risk_labels)
pickle.dump(le_risk, open(os.path.join(OUT, 'risk_label_encoder.pkl'), 'wb'))

X_expiry = np.column_stack([
    np.random.randint(0, len(products), n),
    np.random.randint(1, 500, n),
    np.random.uniform(20, 300, n),
    np.random.uniform(100, 5000, n),
    np.random.randint(1, 13, n),
    np.random.randint(2024, 2027, n),
])

y_expiry = np.where(X_expiry[:, 5] < 2025, 3,
           np.where(X_expiry[:, 5] == 2025, 2,
           np.where(X_expiry[:, 4] <= 6, 1, 0)))

X_train, X_test, y_train, y_test = train_test_split(
    X_expiry, y_expiry, test_size=0.2, random_state=42
)

expiry_model = RandomForestClassifier(n_estimators=50, random_state=42)
expiry_model.fit(X_train, y_train)

y_pred = expiry_model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)

print("Expiry Risk Model Accuracy:", round(accuracy, 3))

pickle.dump(expiry_model, open(os.path.join(OUT, 'expiry_risk_model.pkl'), 'wb'))
print("✓ expiry_risk_model.pkl saved")


# 4. Reorder Prediction Model (Regression)


print("\nTraining Reorder Model...")

le_reorder = LabelEncoder().fit(catalog['product'])
pickle.dump(le_reorder, open(os.path.join(OUT, 'reorder_label_encoder.pkl'), 'wb'))

X_reorder = np.column_stack([
    np.random.randint(0, len(products), n),
    np.random.uniform(1, 50, n),
    np.random.uniform(20, 300, n),
    np.random.randint(1, 10, n),
    np.random.randint(3, 30, n),
])

y_reorder = (X_reorder[:, 1] * X_reorder[:, 4] * 1.5 +
             np.random.normal(0, 5, n)).clip(10, 500)

X_train, X_test, y_train, y_test = train_test_split(
    X_reorder, y_reorder, test_size=0.2, random_state=42
)

reorder_model = RandomForestRegressor(n_estimators=50, random_state=42)
reorder_model.fit(X_train, y_train)

y_pred = reorder_model.predict(X_test)

r2 = r2_score(y_test, y_pred)

print("Reorder Model R2 Score:", round(r2, 3))

pickle.dump(reorder_model, open(os.path.join(OUT, 'reorder_model.pkl'), 'wb'))
print("✓ reorder_model.pkl saved")


# 5. TF-IDF Medicine Alternative Model


print("\nTraining Medicine Alternative Model (TF-IDF)...")

tfidf = TfidfVectorizer(analyzer='char_wb', ngram_range=(2, 4))

matrix = tfidf.fit_transform(catalog['product'])

pickle.dump(tfidf, open(os.path.join(OUT, 'tfidf_vectorizer.pkl'), 'wb'))
pickle.dump(matrix, open(os.path.join(OUT, 'tfidf_matrix.pkl'), 'wb'))

print("✓ tfidf_vectorizer.pkl saved")
print("✓ tfidf_matrix.pkl saved")

# 6. Dead Stock Analysis Data


dead_labels = ['SAFE', 'LIKELY_DEAD', 'DEAD_STOCK']

dead_df = pd.DataFrame({
    'product': np.random.choice(products, 50),
    'total_qty': np.random.randint(0, 200, 50),
    'total_value': np.round(np.random.uniform(100, 5000, 50), 2),
    'total_mrp_val': np.round(np.random.uniform(500, 20000, 50), 2),
    'dead_stock_label': np.random.choice(dead_labels, 50, p=[0.6, 0.25, 0.15]),
})

dead_df.to_csv(os.path.join(OUT, 'dead_stock_analysis.csv'), index=False)

print("✓ dead_stock_analysis.csv saved")

# ─────────────────────────────────────────────────────────

print("\n All models trained successfully and saved in /models folder")