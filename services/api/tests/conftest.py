import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.config import Settings  # noqa: E402
from app.main import create_app  # noqa: E402

REPO = Path(__file__).resolve().parents[3]


@pytest.fixture
def settings():
    return Settings(database_url="sqlite://", jwt_secret="test-secret-" + "x" * 40, auth_rate_per_minute=1000, general_rate_per_minute=10000)


@pytest.fixture
def client(settings):
    return TestClient(create_app(settings))


@pytest.fixture
def auth(client):
    def make(email="user@example.com", pw="correct horse battery"):
        assert client.post("/v1/auth/register", json={"email": email, "password": pw}).status_code == 201
        tok = client.post("/v1/auth/login", json={"email": email, "password": pw}).json()["access_token"]
        return {"Authorization": f"Bearer {tok}"}

    return make
