from flask import Blueprint, jsonify
import os

env = os.getenv('MESSAGE', 'development')


main_bp = Blueprint('main', __name__)

@main_bp.route('/', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "message": "Production Flask app is running inside Docker 🚀. Message " + env
    }), 200