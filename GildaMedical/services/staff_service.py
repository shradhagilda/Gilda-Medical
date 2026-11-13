from database import db
from models.user import Staff, Attendance, Sale
from datetime import datetime, date
from calendar import monthrange


def calculate_monthly_salary(staff_id: int, year: int, month: int) -> dict:
    s = Staff.query.get_or_404(staff_id)
    working_days = 26
    records = Attendance.query.filter_by(staff_id=staff_id).filter(
        db.extract('year', Attendance.date) == year,
        db.extract('month', Attendance.date) == month
    ).all()
    present = len(records)
    absent = max(0, working_days - present)
    late = sum(1 for r in records if r.status == 'late')
    deduction = (absent * 500) + (late * 100)
    return {
        'name': s.name,
        'base_salary': s.salary,
        'present_days': present,
        'absent_days': absent,
        'late_days': late,
        'deduction': deduction,
        'net_salary': round(max(0, s.salary - deduction), 2),
        'month': f'{year}-{month:02d}',
    }


def get_best_employee(months: int = 6) -> dict | None:
    """Score all staff over last N months and return the top performer."""
    staff_list = Staff.query.all()
    if not staff_list:
        return None

    scores = {}
    for s in staff_list:
        # Attendance score (0-40 pts)
        total = Attendance.query.filter_by(staff_id=s.id).count()
        present = Attendance.query.filter_by(staff_id=s.id, status='present').count()
        att_score = (present / max(total, 1)) * 40

        # Sales score (0-40 pts) — count sales handled by staff (approximated by total sales)
        sales_total = db.session.query(db.func.sum(Sale.total)).scalar() or 1
        # We don't have per-staff sales yet; use attendance as proxy for now
        sales_score = att_score  # placeholder until per-staff sales tracking added

        # Accuracy score (0-20 pts) — no late days = full score
        late = Attendance.query.filter_by(staff_id=s.id, status='late').count()
        accuracy_score = max(0, 20 - late * 2)

        scores[s.id] = {
            'id': s.id,
            'name': s.name,
            'role': s.role,
            'score': round(att_score + accuracy_score, 1),
            'attendance_days': present,
            'late_days': late,
        }

    if not scores:
        return None
    winner = max(scores.values(), key=lambda x: x['score'])
    return winner
