from __future__ import annotations

import threading
import time
from collections import defaultdict, deque

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

_ph = PasswordHasher()
# Pre-computed hash so login timing does not reveal whether an email exists.
_DUMMY = _ph.hash("not-a-real-password-placeholder")


def hash_password(pw: str) -> str:
    return _ph.hash(pw)


def verify_password(pw: str, hashed: str | None) -> bool:
    try:
        return _ph.verify(hashed or _DUMMY, pw) and hashed is not None
    except (VerificationError, InvalidHashError):
        return False


def make_token(user_id: int, secret: str, ttl: int) -> str:
    now = int(time.time())
    return jwt.encode({"sub": str(user_id), "iat": now, "exp": now + ttl, "typ": "access"}, secret, algorithm="HS256")


def read_token(token: str, secret: str) -> int | None:
    try:
        data = jwt.decode(token, secret, algorithms=["HS256"], options={"require": ["exp", "sub"]})
    except jwt.PyJWTError:
        return None
    if data.get("typ") != "access":
        return None
    try:
        return int(data["sub"])
    except (TypeError, ValueError):
        return None


class RateLimiter:
    """Fixed 60-second sliding window per (bucket, client). In-process only;
    a multi-instance deployment needs a shared store (documented in ARCHITECTURE.md)."""

    def __init__(self) -> None:
        self._hits: dict[tuple[str, str], deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def allow(self, bucket: str, client: str, limit: int, now: float | None = None) -> bool:
        now = time.monotonic() if now is None else now
        with self._lock:
            q = self._hits[(bucket, client)]
            while q and now - q[0] >= 60:
                q.popleft()
            if len(q) >= limit:
                return False
            q.append(now)
            return True
