from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity, get_jwt
from werkzeug.security import generate_password_hash, check_password_hash
from models.user import User, Alert
from database import db

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(username=data.get('username')).first()
    if not user or not check_password_hash(user.password_hash, data.get('password', '')):
        return jsonify({'error': 'Invalid credentials'}), 401
    if user.status == 'pending':
        return jsonify({'error': 'Account pending approval by admin'}), 403
    if user.status == 'rejected':
        return jsonify({'error': 'Account registration was rejected'}), 403
    token = create_access_token(
        identity=str(user.id),
        additional_claims={'role': user.role, 'username': user.username}
    )
    return jsonify({'token': token, 'role': user.role, 'username': user.username, 'name': user.name})

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    if User.query.filter_by(username=data.get('username')).first():
        return jsonify({'error': 'Username already exists'}), 409
    if User.query.filter_by(email=data.get('email')).first():
        return jsonify({'error': 'Email already registered'}), 409

    role = data.get('role', 'staff')
    # First user to register as admin is auto-approved; others are pending
    status = 'pending' if role != 'admin' else 'approved'
    # If no admin exists yet, auto-approve
    if User.query.filter_by(role='admin', status='approved').count() == 0:
        status = 'approved'

    user = User(
        name=data.get('name'),
        email=data.get('email'),
        username=data.get('username'),
        password_hash=generate_password_hash(data.get('password')),
        role=role,
        status=status,
        phone=data.get('phone'),
        pharmacy_name=data.get('pharmacy_name'),
        license_number=data.get('license_number'),
    )
    db.session.add(user)
    db.session.flush()

    if status == 'pending':
        alert = Alert(
            type='registration',
            message=f"New {role} registration: {data.get('name')} ({data.get('email')}). Action required."
        )
        db.session.add(alert)

    db.session.commit()
    return jsonify({'message': 'Registration submitted', 'status': status}), 201

@auth_bp.route('/pending-users', methods=['GET'])
@jwt_required()
def pending_users():
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin only'}), 403
    users = User.query.filter_by(status='pending').all()
    return jsonify([{
        'id': u.id, 'name': u.name, 'email': u.email,
        'username': u.username, 'role': u.role,
        'pharmacy_name': u.pharmacy_name, 'phone': u.phone,
        'created_at': str(u.created_at)
    } for u in users])

@auth_bp.route('/approve/<int:user_id>', methods=['PUT'])
@jwt_required()
def approve_user(user_id):
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin only'}), 403
    action = request.json.get('action')  # 'approve' or 'reject'
    user = User.query.get_or_404(user_id)
    user.status = 'approved' if action == 'approve' else 'rejected'
    user.approved_by = int(get_jwt_identity())
    db.session.commit()
    return jsonify({'message': f'User {user.status}', 'username': user.username})

@auth_bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin only'}), 403
    users = User.query.all()
    return jsonify([{'id': u.id, 'name': u.name, 'username': u.username,
                     'role': u.role, 'status': u.status, 'email': u.email} for u in users])
