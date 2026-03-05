from flask import Flask, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from src.config.settings import settings

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = settings.DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = settings.SECRET_KEY

# Inicializar extensiones
db = SQLAlchemy(app)
CORS(app, origins=settings.ALLOWED_ORIGINS)


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'ok',
        'app': settings.APP_NAME
    })


@app.route('/api/v1/example', methods=['GET'])
def example_endpoint():
    return jsonify({
        'message': 'Flask API funcionando',
        'version': '0.1.0'
    })


if __name__ == '__main__':
    app.run(
        host=settings.API_HOST,
        port=settings.API_PORT,
        debug=settings.DEBUG
    )