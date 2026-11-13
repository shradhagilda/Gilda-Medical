from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash
from datetime import datetime

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

db = SQLAlchemy()

def init_db(app):
    db.init_app(app)
    with app.app_context():
        db.create_all()
        _seed_default_users()

def _seed_default_users():
    from models.user import User
    if User.query.count() == 0:
        users = [
            User(name='Administrator', email='admin@gilda.com', username='admin',
                 password_hash=generate_password_hash('admin123'), role='admin', status='approved'),
            User(name='Pharmacist', email='pharma@gilda.com', username='pharmacist',
                 password_hash=generate_password_hash('pharma123'), role='pharmacist', status='approved'),
            User(name='Staff Member', email='staff@gilda.com', username='staff',
                 password_hash=generate_password_hash('staff123'), role='staff', status='approved'),
        ]
        db.session.add_all(users)
        db.session.commit()
