from database import db
from datetime import datetime

class User(db.Model):
    id           = db.Column(db.Integer, primary_key=True)
    name         = db.Column(db.String(100), nullable=False)
    email        = db.Column(db.String(120), unique=True, nullable=False)
    username     = db.Column(db.String(50), unique=True, nullable=False)
    password_hash= db.Column(db.String(200), nullable=False)
    role         = db.Column(db.String(20), nullable=False)  # admin/pharmacist/staff
    status       = db.Column(db.String(20), default='approved')  # pending/approved/rejected
    phone        = db.Column(db.String(20))
    pharmacy_name= db.Column(db.String(100))
    license_number=db.Column(db.String(50))
    created_at   = db.Column(db.DateTime, default=datetime.utcnow)
    approved_by  = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)

class Medicine(db.Model):
    id             = db.Column(db.Integer, primary_key=True)
    name           = db.Column(db.String(100), nullable=False)
    batch_no       = db.Column(db.String(50))
    expiry_date    = db.Column(db.String(20))
    supplier       = db.Column(db.String(100))
    purchase_price = db.Column(db.Float, default=0)
    selling_price  = db.Column(db.Float, default=0)
    quantity       = db.Column(db.Integer, default=0)
    barcode        = db.Column(db.String(50))
    company        = db.Column(db.String(100))
    packing        = db.Column(db.String(50))
    created_at     = db.Column(db.DateTime, default=datetime.utcnow)

class Sale(db.Model):
    id          = db.Column(db.Integer, primary_key=True)
    medicine_id = db.Column(db.Integer, db.ForeignKey('medicine.id'))
    customer    = db.Column(db.String(100))
    quantity    = db.Column(db.Integer)
    total       = db.Column(db.Float)
    date        = db.Column(db.DateTime, default=datetime.utcnow)

class Customer(db.Model):
    id               = db.Column(db.Integer, primary_key=True)
    name             = db.Column(db.String(100))
    contact          = db.Column(db.String(20))
    purchase_history = db.Column(db.Text)

class Staff(db.Model):
    id         = db.Column(db.Integer, primary_key=True)
    name       = db.Column(db.String(100))
    role       = db.Column(db.String(50))
    salary     = db.Column(db.Float)
    attendance = db.Column(db.Integer, default=0)
    leaves     = db.Column(db.Integer, default=0)
    joined     = db.Column(db.DateTime, default=datetime.utcnow)

class Attendance(db.Model):
    id         = db.Column(db.Integer, primary_key=True)
    staff_id   = db.Column(db.Integer, db.ForeignKey('staff.id'))
    date       = db.Column(db.Date, default=datetime.utcnow)
    check_in   = db.Column(db.DateTime, nullable=True)
    check_out  = db.Column(db.DateTime, nullable=True)
    status     = db.Column(db.String(20), default='absent')  # present/late/absent/holiday

class Alert(db.Model):
    id      = db.Column(db.Integer, primary_key=True)
    type    = db.Column(db.String(50))   # expiry/stock/fraud/registration
    message = db.Column(db.String(200))
    status  = db.Column(db.String(20), default='unread')
    date    = db.Column(db.DateTime, default=datetime.utcnow)

class PurchaseOrder(db.Model):
    id          = db.Column(db.Integer, primary_key=True)
    medicine_id = db.Column(db.Integer, db.ForeignKey('medicine.id'))
    quantity    = db.Column(db.Integer)
    supplier    = db.Column(db.String(100))
    status      = db.Column(db.String(20), default='pending')
    date        = db.Column(db.DateTime, default=datetime.utcnow)
