from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from models.user import Alert, Medicine
from database import db
from datetime import datetime

alerts_bp = Blueprint('alerts', __name__)

@alerts_bp.route('/', methods=['GET'])
@jwt_required()
def get_alerts():
    alerts = Alert.query.order_by(Alert.date.desc()).limit(50).all()
    return jsonify([{'id': a.id, 'type': a.type, 'message': a.message,
                     'status': a.status, 'date': str(a.date)} for a in alerts])

@alerts_bp.route('/unread-count', methods=['GET'])
@jwt_required()
def unread_count():
    return jsonify({'unread': Alert.query.filter_by(status='unread').count()})

@alerts_bp.route('/mark-read/<int:id>', methods=['PUT'])
@jwt_required()
def mark_read(id):
    a = Alert.query.get_or_404(id)
    a.status = 'read'
    db.session.commit()
    return jsonify({'message': 'Marked as read'})

@alerts_bp.route('/generate', methods=['POST'])
@jwt_required()
def generate_alerts():
    count = 0
    for m in Medicine.query.all():
        try:
            exp = datetime.strptime(m.expiry_date, '%m/%y')
            days = (exp - datetime.today()).days
            if 0 < days <= 30:
                db.session.add(Alert(type='expiry',
                    message=f"URGENT: {m.name} expires in {days} days"))
                count += 1
        except: pass
        if m.quantity <= 5:
            db.session.add(Alert(type='stock',
                message=f"Critical: {m.name} only {m.quantity} units left"))
            count += 1
    db.session.commit()
    return jsonify({'message': f'{count} alerts generated'})
