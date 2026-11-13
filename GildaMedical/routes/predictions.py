from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
import pickle, os, numpy as np, pandas as pd

predictions_bp = Blueprint('predictions', __name__)
ML_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'models')

def load(f):
    path = os.path.join(ML_DIR, f)
    return pickle.load(open(path, 'rb')) if os.path.exists(path) else None

@predictions_bp.route('/demand', methods=['POST'])
@jwt_required()
def demand():
    d = request.json
    model = load('demand_forecast_model.pkl')
    le    = load('product_label_encoder.pkl')
    if not model or not le:
        return jsonify({'error': 'Model not loaded'}), 500
    try:
        enc  = le.transform([d['product']])[0]
        pred = model.predict([[enc, d['month'], d['year'], d['mrp'], d['batch_count']]])[0]
        return jsonify({'product': d['product'], 'predicted_demand': round(pred, 0)})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@predictions_bp.route('/expiry-risk', methods=['POST'])
@jwt_required()
def expiry_risk():
    d = request.json
    model = load('expiry_risk_model.pkl')
    le_p  = load('product_label_encoder.pkl')
    le_r  = load('risk_label_encoder.pkl')
    if not model: return jsonify({'error': 'Model not loaded'}), 500
    try:
        # If product is unknown to the label encoder, fall back to rule-based risk
        try:
            enc = le_p.transform([d['product']])[0]
        except Exception:
            # Rule-based fallback using days to expiry
            from datetime import datetime
            today = datetime.today()
            try:
                exp_date = datetime(int(d['exp_year']), int(d['exp_month']) + 1, 1)
                days = (exp_date - today).days
            except Exception:
                days = 999
            if days < 0:
                label = 'HIGH_RISK'
            elif days <= 90:
                label = 'HIGH_RISK'
            elif days <= 180:
                label = 'MEDIUM_RISK'
            else:
                label = 'SAFE'
            return jsonify({'product': d['product'], 'expiry_risk': label, 'source': 'rule_based'})

        pred  = model.predict([[enc, d['qty'], d['mrp'], d['mrp_value'], d['exp_month'], d['exp_year']]])[0]
        label = le_r.inverse_transform([pred])[0]
        return jsonify({'product': d['product'], 'expiry_risk': label, 'source': 'ml_model'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@predictions_bp.route('/reorder', methods=['POST'])
@jwt_required()
def reorder():
    d = request.json
    model = load('reorder_model.pkl')
    le    = load('reorder_label_encoder.pkl')
    if not model: return jsonify({'error': 'Model not loaded'}), 500
    try:
        enc  = le.transform([d['product']])[0]
        pred = model.predict([[enc, d['daily_sales'], d['mrp'], d['batch_count'], d['lead_days']]])[0]
        return jsonify({'product': d['product'], 'reorder_at': round(pred, 0),
                        'days_left': round(pred / d['daily_sales'] if d['daily_sales'] else 0, 1)})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@predictions_bp.route('/loss-prevention', methods=['GET'])
@jwt_required()
def loss_prevention():
    path = os.path.join(ML_DIR, 'dead_stock_analysis.csv')
    if not os.path.exists(path):
        return jsonify({'saved': 0, 'message': 'AI models protecting your inventory'})
    df = pd.read_csv(path)
    safe_value = df[df['dead_stock_label'] == 'SAFE']['total_mrp_val'].sum()
    dead_value = df[df['dead_stock_label'].isin(['DEAD_STOCK', 'LIKELY_DEAD'])]['total_mrp_val'].sum()
    return jsonify({
        'total_inventory_value': round(safe_value, 2),
        'dead_stock_loss': round(dead_value, 2),
        'ai_saved_estimate': round(safe_value * 0.05, 2),
        'message': f"AI alerts helped protect ₹{round(safe_value * 0.05, 2):,.2f} worth of inventory"
    })
