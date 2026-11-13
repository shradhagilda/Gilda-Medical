from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models.user import Medicine, Alert
from database import db
from datetime import datetime

medicine_bp = Blueprint('medicine', __name__)

def medicine_to_dict(m):
    today = datetime.today()
    days_left = None
    risk = 'SAFE'
    try:
        exp = datetime.strptime(m.expiry_date, '%m/%y') if m.expiry_date else None
        if exp:
            days_left = (exp - today).days
            if days_left < 0:    risk = 'EXPIRED'
            elif days_left < 90: risk = 'HIGH_RISK'
            elif days_left < 180:risk = 'MEDIUM_RISK'
    except: pass
    return {
        'id': m.id, 'name': m.name, 'batch_no': m.batch_no,
        'expiry_date': m.expiry_date, 'supplier': m.supplier,
        'purchase_price': m.purchase_price, 'selling_price': m.selling_price,
        'quantity': m.quantity, 'barcode': m.barcode,
        'company': m.company, 'packing': m.packing,
        'days_to_expiry': days_left, 'expiry_risk': risk
    }

@medicine_bp.route('/', methods=['GET'])
@jwt_required()
def get_all():
    search = request.args.get('search', '')
    page   = int(request.args.get('page', 1))
    limit  = min(int(request.args.get('limit', 100)), 500)  # max 500 per page
    query  = Medicine.query.filter(Medicine.name.ilike(f'%{search}%'))
    # also search by barcode and batch_no
    if search:
        query = Medicine.query.filter(
            db.or_(
                Medicine.name.ilike(f'%{search}%'),
                Medicine.barcode.ilike(f'%{search}%'),
                Medicine.batch_no.ilike(f'%{search}%'),
            )
        )
    total  = query.count()
    meds   = query.offset((page - 1) * limit).limit(limit).all()
    return jsonify({'data': [medicine_to_dict(m) for m in meds], 'total': total, 'page': page, 'limit': limit})

@medicine_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_one(id):
    return jsonify(medicine_to_dict(Medicine.query.get_or_404(id)))

@medicine_bp.route('/', methods=['POST'])
@jwt_required()
def add():
    d = request.json
    m = Medicine(**d)
    db.session.add(m)
    db.session.commit()
    if d.get('expiry_date'):
        try:
            exp = datetime.strptime(d['expiry_date'], '%m/%y')
            days = (exp - datetime.today()).days
            if days < 90:
                db.session.add(Alert(type='expiry',
                    message=f"{d['name']} expires in {days} days (Batch: {d.get('batch_no','')})"))
                db.session.commit()
        except: pass
    return jsonify({'message': 'Medicine added', 'id': m.id}), 201

@medicine_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update(id):
    m = Medicine.query.get_or_404(id)
    for k, v in request.json.items():
        setattr(m, k, v)
    db.session.commit()
    return jsonify({'message': 'Updated'})

@medicine_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete(id):
    m = Medicine.query.get_or_404(id)
    db.session.delete(m)
    db.session.commit()
    return jsonify({'message': 'Deleted'})

@medicine_bp.route('/barcode/<code>', methods=['GET'])
@jwt_required()
def by_barcode(code):
    m = Medicine.query.filter_by(barcode=code).first()
    if not m: return jsonify({'error': 'Not found'}), 404
    return jsonify(medicine_to_dict(m))

@medicine_bp.route('/expiring-soon', methods=['GET'])
@jwt_required()
def expiring_soon():
    today = datetime.today()
    result = []
    for m in Medicine.query.all():
        try:
            exp = datetime.strptime(m.expiry_date, '%m/%y')
            days = (exp - today).days
            if 0 <= days <= 90:
                result.append(medicine_to_dict(m))
        except: pass
    return jsonify(sorted(result, key=lambda x: x['days_to_expiry']))

@medicine_bp.route('/low-stock', methods=['GET'])
@jwt_required()
def low_stock():
    threshold = int(request.args.get('threshold', 10))
    return jsonify([medicine_to_dict(m) for m in Medicine.query.filter(Medicine.quantity <= threshold).all()])
