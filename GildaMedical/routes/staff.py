from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models.user import Staff, Attendance
from database import db
from services.staff_service import calculate_monthly_salary
from datetime import datetime, date

staff_bp = Blueprint('staff', __name__)

@staff_bp.route('/', methods=['GET'])
@jwt_required()
def get_all():
    staff = Staff.query.all()
    return jsonify([{'id': s.id, 'name': s.name, 'role': s.role,
                     'salary': s.salary, 'attendance': s.attendance, 'leaves': s.leaves}
                    for s in staff])

@staff_bp.route('/', methods=['POST'])
@jwt_required()
def add():
    d = request.json
    s = Staff(**d)
    db.session.add(s)
    db.session.commit()
    return jsonify({'message': 'Staff added', 'id': s.id}), 201

@staff_bp.route('/attendance/checkin/<int:staff_id>', methods=['POST'])
@jwt_required()
def check_in(staff_id):
    s = Staff.query.get_or_404(staff_id)
    today = date.today()
    existing = Attendance.query.filter_by(staff_id=staff_id, date=today).first()
    if existing:
        return jsonify({'error': 'Already checked in today'}), 400
    now = datetime.now()
    # Late if after 9:30 AM
    status = 'late' if now.hour > 9 or (now.hour == 9 and now.minute > 30) else 'present'
    att = Attendance(staff_id=staff_id, date=today, check_in=now, status=status)
    db.session.add(att)
    s.attendance += 1
    db.session.commit()
    return jsonify({'message': f'Check-in recorded for {s.name}', 'status': status,
                    'time': now.strftime('%H:%M')})

@staff_bp.route('/attendance/checkout/<int:staff_id>', methods=['POST'])
@jwt_required()
def check_out(staff_id):
    today = date.today()
    att = Attendance.query.filter_by(staff_id=staff_id, date=today).first()
    if not att:
        return jsonify({'error': 'No check-in found for today'}), 400
    att.check_out = datetime.now()
    db.session.commit()
    return jsonify({'message': 'Check-out recorded', 'time': att.check_out.strftime('%H:%M')})

@staff_bp.route('/attendance/<int:staff_id>', methods=['GET'])
@jwt_required()
def get_attendance(staff_id):
    records = Attendance.query.filter_by(staff_id=staff_id).order_by(Attendance.date.desc()).limit(30).all()
    return jsonify([{
        'date': str(r.date), 'status': r.status,
        'check_in': r.check_in.strftime('%H:%M') if r.check_in else None,
        'check_out': r.check_out.strftime('%H:%M') if r.check_out else None,
    } for r in records])

@staff_bp.route('/salary/<int:staff_id>', methods=['GET'])
@jwt_required()
def calculate_salary(staff_id):
    month = request.args.get('month', datetime.today().strftime('%Y-%m'))
    year, mon = map(int, month.split('-'))
    return jsonify(calculate_monthly_salary(staff_id, year, mon))

@staff_bp.route('/summary', methods=['GET'])
@jwt_required()
def summary():
    staff = Staff.query.all()
    today_present = Attendance.query.filter_by(date=date.today()).count()
    return jsonify({
        'total_staff': len(staff),
        'present_today': today_present,
        'total_salary': sum(s.salary for s in staff),
        'staff': [{'name': s.name, 'role': s.role, 'attendance': s.attendance} for s in staff]
    })
