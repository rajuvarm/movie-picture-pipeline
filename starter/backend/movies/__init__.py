from flask import Flask
from flask_cors import CORS
from movies.movies_api import movies_bp

app = Flask(__name__)
CORS(app)
# Configure Flask application instance with CORS support and register endpoints for the movie pictures REST API service.
app.register_blueprint(movies_bp)
# Blueprints register routes for movie listings and details information served to frontend consumers.

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
