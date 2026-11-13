from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models.user import Medicine, Sale
from database import db
from datetime import datetime, timedelta
import pickle, numpy as np, pandas as pd, os
from sklearn.metrics.pairwise import cosine_similarity

analytics_bp = Blueprint('analytics', __name__)
ML_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'models')

def load(f):
    path = os.path.join(ML_DIR, f)
    return pickle.load(open(path, 'rb')) if os.path.exists(path) else None

@analytics_bp.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard():
    today = datetime.today().date()
    sales_today = Sale.query.filter(db.func.date(Sale.date) == today).all()
    revenue = sum(s.total for s in sales_today)
    meds = Medicine.query.all()
    expiring, low_stock = [], []
    for m in meds:
        try:
            exp = datetime.strptime(m.expiry_date, '%m/%y')
            if 0 <= (exp - datetime.today()).days <= 90:
                expiring.append(m.name)
        except: pass
        if m.quantity <= 10:
            low_stock.append(m.name)

    from models.user import Staff, Attendance
    from datetime import date as date_type
    total_staff = Staff.query.count()
    present_today = Attendance.query.filter_by(date=date_type.today()).count()

    return jsonify({
        'today_revenue': round(revenue, 2),
        'transactions_today': len(sales_today),
        'expiring_soon_count': len(expiring),
        'expiring_soon': expiring[:5],
        'low_stock_count': len(low_stock),
        'low_stock': low_stock[:5],
        'total_medicines': len(meds),
        'staff_total': total_staff,
        'staff_present_today': present_today,
    })

@analytics_bp.route('/sales-chart', methods=['GET'])
@jwt_required()
def sales_chart():
    days = int(request.args.get('days', 30))
    result = []
    for i in range(days):
        d = (datetime.today() - timedelta(days=i)).date()
        sales = Sale.query.filter(db.func.date(Sale.date) == d).all()
        result.append({'date': str(d), 'revenue': round(sum(s.total for s in sales), 2)})
    return jsonify(result[::-1])

@analytics_bp.route('/top-medicines', methods=['GET'])
@jwt_required()
def top_medicines():
    counts = {}
    for s in Sale.query.all():
        counts[s.medicine_id] = counts.get(s.medicine_id, 0) + s.quantity
    top = sorted(counts.items(), key=lambda x: x[1], reverse=True)[:10]
    result = []
    for mid, qty in top:
        m = Medicine.query.get(mid)
        if m: result.append({'name': m.name, 'total_sold': qty})
    return jsonify(result)

@analytics_bp.route('/dead-stock', methods=['GET'])
@jwt_required()
def dead_stock():
    path = os.path.join(ML_DIR, 'dead_stock_analysis.csv')
    if not os.path.exists(path):
        return jsonify({'error': 'Dead stock analysis not available'}), 404
    df = pd.read_csv(path)
    dead = df[df['dead_stock_label'].isin(['DEAD_STOCK', 'LIKELY_DEAD'])][
        ['product', 'total_qty', 'total_value', 'dead_stock_label']].head(20)
    return jsonify(dead.to_dict(orient='records'))

@analytics_bp.route('/alternatives', methods=['GET'])
@jwt_required()
def alternatives():
    medicine = request.args.get('medicine', '')
    tfidf = load('tfidf_vectorizer.pkl')
    matrix = load('tfidf_matrix.pkl')
    catalog_path = os.path.join(ML_DIR, 'product_catalog.csv')
    catalog = pd.read_csv(catalog_path) if os.path.exists(catalog_path) else None
    if tfidf is None or matrix is None or catalog is None:
        return jsonify({'error': 'Model not loaded'}), 500
    matches = catalog[catalog['product'].str.contains(medicine, case=False, na=False)]
    if matches.empty:
        return jsonify({'error': f"'{medicine}' not found"}), 404
    idx = matches.index[0]
    scores = cosine_similarity(matrix[idx], matrix).flatten()
    top = [i for i in np.argsort(scores)[::-1] if i != idx][:5]
    return jsonify({'medicine': medicine, 'alternatives': [
        {'name': catalog.iloc[i]['product'], 'packing': catalog.iloc[i]['packing'],
         'avg_mrp': round(catalog.iloc[i]['avg_mrp'], 2), 'similarity': round(scores[i] * 100, 1)}
        for i in top
    ]})

@analytics_bp.route('/gst-report', methods=['GET'])
@jwt_required()
def gst_report():
    month = request.args.get('month', datetime.today().strftime('%Y-%m'))
    total = sum(s.total for s in Sale.query.all())
    return jsonify({
        'month': month, 'total_sales': round(total, 2),
        'cgst_9pct': round(total * 0.09, 2),
        'sgst_9pct': round(total * 0.09, 2),
        'total_gst': round(total * 0.18, 2),
        'net_payable': round(total * 1.18, 2)
    })
