from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models.user import Sale, Medicine, Alert
from database import db
from datetime import datetime

billing_bp = Blueprint('billing', __name__)

@billing_bp.route('/sell', methods=['POST'])
@jwt_required()
def sell():
    data = request.json
    items = data.get('items', [])
    customer = data.get('customer', 'Walk-in')
    total_bill = 0
    bill_items = []

    for item in items:
        med = Medicine.query.get(item['medicine_id'])
        if not med:
            return jsonify({'error': f"Medicine ID {item['medicine_id']} not found"}), 404
        if med.quantity < item['quantity']:
            return jsonify({'error': f"Insufficient stock for {med.name}"}), 400
        subtotal = med.selling_price * item['quantity']
        total_bill += subtotal
        med.quantity -= item['quantity']
        db.session.add(Sale(medicine_id=med.id, customer=customer,
                            quantity=item['quantity'], total=subtotal))
        bill_items.append({'name': med.name, 'batch': med.batch_no,
                           'qty': item['quantity'], 'price': med.selling_price, 'subtotal': subtotal})
        if med.quantity <= 10:
            db.session.add(Alert(type='stock',
                message=f"Low stock: {med.name} has only {med.quantity} units left"))

    db.session.commit()
    return jsonify({
        'message': 'Sale successful', 'customer': customer,
        'items': bill_items, 'total': round(total_bill, 2),
        'gst': round(total_bill * 0.12, 2),
        'grand_total': round(total_bill * 1.12, 2),
        'date': datetime.now().strftime('%d-%m-%Y %H:%M')
    })

@billing_bp.route('/history', methods=['GET'])
@jwt_required()
def history():
    sales = Sale.query.order_by(Sale.date.desc()).limit(50).all()
    return jsonify([{'id': s.id, 'medicine_id': s.medicine_id, 'customer': s.customer,
                     'quantity': s.quantity, 'total': s.total, 'date': str(s.date)} for s in sales])

@billing_bp.route('/today-revenue', methods=['GET'])
@jwt_required()
def today_revenue():
    today = datetime.today().date()
    sales = Sale.query.filter(db.func.date(Sale.date) == today).all()
    revenue = sum(s.total for s in sales)
    return jsonify({'date': str(today), 'revenue': round(revenue, 2), 'transactions': len(sales)})
