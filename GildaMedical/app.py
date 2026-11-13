import os
from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from routes.auth import auth_bp
from routes.medicine import medicine_bp
from routes.billing import billing_bp
from routes.analytics import analytics_bp
from routes.alerts import alerts_bp
from routes.staff import staff_bp
from routes.predictions import predictions_bp
from routes.rewards import rewards_bp
from database import init_db

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET', 'gilda-medical-secret-2024')

# Use absolute path so SQLite always finds the folder
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DB_PATH = os.path.join(BASE_DIR, 'instance', 'gilda_medical.db')
os.makedirs(os.path.join(BASE_DIR, 'instance'), exist_ok=True)
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{DB_PATH}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

CORS(app, origins="*", supports_credentials=False)
JWTManager(app)

app.register_blueprint(auth_bp,        url_prefix='/api/auth')
app.register_blueprint(medicine_bp,    url_prefix='/api/medicine')
app.register_blueprint(billing_bp,     url_prefix='/api/billing')
app.register_blueprint(analytics_bp,   url_prefix='/api/analytics')
app.register_blueprint(alerts_bp,      url_prefix='/api/alerts')
app.register_blueprint(staff_bp,       url_prefix='/api/staff')
app.register_blueprint(predictions_bp, url_prefix='/api/predictions')
app.register_blueprint(rewards_bp,     url_prefix='/api/rewards')

@app.route('/')
def home():
    return {'app': 'Gilda Medical API', 'version': '2.1', 'status': 'running'}

if __name__ == '__main__':
    init_db(app)
    app.run(debug=True, host='0.0.0.0', port=5001)
