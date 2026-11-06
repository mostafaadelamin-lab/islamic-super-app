import time

import jwt
import pytest

from app.security import RateLimiter, make_token, read_token


def test_register_login_me(client, auth):
    h = auth("A@Example.com")
    me = client.get("/v1/me", headers=h).json()
    assert me["email"] == "a@example.com"


def test_duplicate_email_case_insensitive(client, auth):
    auth("dup@example.com")
    r = client.post("/v1/auth/register", json={"email": "DUP@example.com", "password": "another long pw"})
    assert r.status_code == 409


@pytest.mark.parametrize(
    "body",
    [
        {"email": "x@example.com", "password": "short"},
        {"email": "not-an-email", "password": "long enough pw"},
        {"email": "x@example.com"},
        {"email": "x@example.com", "password": "long enough pw", "admin": True},
    ],
)
def test_register_validation(client, body):
    assert client.post("/v1/auth/register", json=body).status_code == 422


def test_password_is_hashed_not_stored(client, auth):
    auth("h@example.com", "plain text secret 1")
    from app.db.models import User

    with client.app.state.db.factory() as s:
        u = s.query(User).filter_by(email="h@example.com").one()
        assert "plain text secret 1" not in u.password_hash and u.password_hash.startswith("$argon2")


def test_login_wrong_password_and_unknown_user(client, auth):
    auth("w@example.com", "right password!")
    assert client.post("/v1/auth/login", json={"email": "w@example.com", "password": "wrong password!"}).status_code == 401
    assert client.post("/v1/auth/login", json={"email": "nobody@example.com", "password": "wrong password!"}).status_code == 401


@pytest.mark.parametrize("hdr", [None, "Bearer", "Bearer abc.def.ghi", "Basic Zm9vOmJhcg=="])
def test_me_requires_valid_token(client, hdr):
    headers = {"Authorization": hdr} if hdr else {}
    assert client.get("/v1/me", headers=headers).status_code in (401, 403)


def test_token_signed_with_other_secret_rejected(client, auth):
    auth("t@example.com")
    forged = make_token(1, "another-secret-" + "y" * 40, 3600)
    assert client.get("/v1/me", headers={"Authorization": f"Bearer {forged}"}).status_code == 401


def test_expired_token_rejected(settings):
    tok = jwt.encode({"sub": "1", "exp": int(time.time()) - 10, "typ": "access"}, settings.jwt_secret, algorithm="HS256")
    assert read_token(tok, settings.jwt_secret) is None


def test_alg_none_rejected(settings):
    tok = jwt.encode({"sub": "1", "exp": int(time.time()) + 100, "typ": "access"}, key=None, algorithm="none")
    assert read_token(tok, settings.jwt_secret) is None


def test_token_for_deleted_user_rejected(client, settings):
    tok = make_token(999, settings.jwt_secret, 3600)
    assert client.get("/v1/me", headers={"Authorization": f"Bearer {tok}"}).status_code == 401


def test_rate_limiter_unit():
    rl = RateLimiter()
    assert all(rl.allow("b", "ip", 3, now=t) for t in (0, 1, 2))
    assert not rl.allow("b", "ip", 3, now=3)
    assert rl.allow("b", "other-ip", 3, now=3)
    assert rl.allow("b", "ip", 3, now=61)


def test_auth_endpoints_rate_limited():
    from fastapi.testclient import TestClient

    from app.config import Settings
    from app.main import create_app

    c = TestClient(create_app(Settings(database_url="sqlite://", jwt_secret="s" * 48, auth_rate_per_minute=10)))
    codes = [c.post("/v1/auth/login", json={"email": "a@example.com", "password": "whatever pw"}).status_code for _ in range(11)]
    assert codes[:10] == [401] * 10 and codes[10] == 429
    assert c.get("/health").status_code == 200  # other buckets unaffected


def test_general_rate_limit():
    from fastapi.testclient import TestClient

    from app.config import Settings
    from app.main import create_app

    c = TestClient(create_app(Settings(database_url="sqlite://", general_rate_per_minute=5)))
    codes = [c.get("/health").status_code for _ in range(6)]
    assert codes == [200] * 5 + [429]
