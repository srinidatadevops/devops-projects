from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_health_without_database():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "not_configured"}


def test_items():
    response = client.get("/items")

    assert response.status_code == 200
    assert response.json() == [
        {"id": 1, "name": "deployment", "status": "ready"},
        {"id": 2, "name": "observability", "status": "ready"},
    ]
