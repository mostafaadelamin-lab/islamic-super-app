from __future__ import annotations

import os
import secrets
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]


@dataclass(frozen=True)
class Settings:
    database_url: str = field(default_factory=lambda: os.getenv("ISA_DATABASE_URL", "sqlite:///./isa.db"))
    # A random secret per process if none is configured: tokens then die on restart,
    # which is safe. Production must set ISA_JWT_SECRET (>= 32 chars).
    jwt_secret: str = field(default_factory=lambda: os.getenv("ISA_JWT_SECRET") or secrets.token_urlsafe(48))
    jwt_ttl_seconds: int = int(os.getenv("ISA_JWT_TTL", "2592000"))
    cors_origins: tuple[str, ...] = tuple(
        o for o in os.getenv("ISA_CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000,http://localhost:4173,http://127.0.0.1:4173").split(",") if o
    )
    auth_rate_per_minute: int = int(os.getenv("ISA_AUTH_RATE", "10"))
    general_rate_per_minute: int = int(os.getenv("ISA_GENERAL_RATE", "120"))
    content_dir: Path = REPO_ROOT / "content"


def get_settings() -> Settings:
    return Settings()
