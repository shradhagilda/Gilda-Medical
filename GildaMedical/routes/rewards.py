from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from services.staff_service import get_best_employee

rewards_bp = Blueprint('rewards', __name__)

@rewards_bp.route('/best-employee', methods=['GET'])
@jwt_required()
def best_employee():
    winner = get_best_employee(months=6)
    if not winner:
        return jsonify({'message': 'No staff data available'}), 404
    return jsonify({
        'winner': winner,
        'reward': '🏆 Employee of the Half-Year',
        'period': '6 months',
        'message': f"Congratulations {winner['name']}! Outstanding performance with a score of {winner['score']}/60."
    })
