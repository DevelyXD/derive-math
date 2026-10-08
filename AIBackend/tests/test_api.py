import os

os.environ["DERIVE_PAIRING_TOKEN"] = "test-token"

from fastapi.testclient import TestClient
import pytest

from app.main import app


@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client


def test_verify_requires_authentication(client: TestClient) -> None:
    assert client.post("/api/verify", json={"steps": ["1=1"]}).status_code == 401


def test_verify_endpoint(client: TestClient) -> None:
    response = client.post(
        "/api/verify",
        headers={"Authorization": "Bearer test-token"},
        json={"steps": ["2x+6=18", "x=6"]},
    )
    assert response.status_code == 200
    assert response.json()["results"][-1]["status"] == "correct"


def test_manual_recognition_fallback(client: TestClient) -> None:
    response = client.post(
        "/api/recognize",
        headers={"Authorization": "Bearer test-token"},
        json={"manual_expression": "x^2 = 4"},
    )
    assert response.status_code == 200
    assert response.json()["source"] == "manual"
