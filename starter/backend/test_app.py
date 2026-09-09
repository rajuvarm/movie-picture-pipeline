import os
from movies import app


def test_movies_endpoint_returns_200():
    with app.test_client() as client:
        status_code = int(os.getenv("FAIL_TEST", "200"))
        response = client.get("/movies/")
        assert response.status_code == status_code


def test_movies_endpoint_returns_json():
    with app.test_client() as client:
        response = client.get("/movies/")
        assert response.is_json


def test_movies_endpoint_returns_valid_data():
    with app.test_client() as client:
        response = client.get("/movies/")
        data = response.get_json()
        assert "movies" in data
        assert len(data["movies"]) == 3
        assert data["movies"][0]["id"] == "123"
        assert data["movies"][0]["title"] == "Top Gun: Maverick"
        assert data["movies"]["id"] == "456"
        assert data["movies"]["title"] == "Sonic the Hedgehog"
        assert data["movies"]["id"] == "789"
        assert data["movies"]["title"] == "A Quiet Place"
