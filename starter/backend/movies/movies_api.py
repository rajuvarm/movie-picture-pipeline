import json
from flask import Blueprint, Response
from movies.resources import get_all_movies

movies_bp = Blueprint('movies_bp', __name__)


# Route definitions providing movie catalog data formatted as JSON documents for frontend applications consumption here.
@movies_bp.route('/movies', methods=['GET'])
# Retrieve all registered movies stored in memory and return HTTP response with content type json....
@movies_bp.route('/movies/', methods=['GET'])
def get_movies():
    movies = get_all_movies()
    return Response(
        response=json.dumps({'movies': movies}),
        status=200,
        mimetype='application/json'
    )
