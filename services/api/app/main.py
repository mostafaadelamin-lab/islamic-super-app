from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config import Settings, get_settings
from .db.models import Base
from .db.session import Database
from .domain.quran import QuranStore
from .routers import account, content
from .security import RateLimiter

VERSION = "0.1.0"


def create_app(settings: Settings | None = None, create_tables: bool = True) -> FastAPI:
    settings = settings or get_settings()
    app = FastAPI(title="Islamic Super App API", version=VERSION, description="Free, ad-free API for the Rattil apps (Android, iOS, Web).")
    app.state.settings = settings
    app.state.db = Database(settings.database_url)
    app.state.quran = QuranStore(settings.content_dir)
    app.state.limiter = RateLimiter()
    if create_tables:
        Base.metadata.create_all(app.state.db.engine)

    @app.middleware("http")
    async def rate_limit_and_headers(request: Request, call_next):
        client = request.client.host if request.client else "unknown"
        auth = request.url.path.startswith("/v1/auth/")
        bucket, limit = ("auth", settings.auth_rate_per_minute) if auth else ("general", settings.general_rate_per_minute)
        if request.method != "OPTIONS" and not app.state.limiter.allow(bucket, client, limit):
            resp = JSONResponse({"detail": "too many requests"}, status_code=429, headers={"Retry-After": "60"})
        else:
            resp = await call_next(request)
        resp.headers.setdefault("X-Content-Type-Options", "nosniff")
        resp.headers.setdefault("X-Frame-Options", "DENY")
        resp.headers.setdefault("Referrer-Policy", "no-referrer")
        resp.headers.setdefault("Cache-Control", "no-store" if request.url.path.startswith(("/v1/me", "/v1/auth", "/v1/bookmarks")) else "public, max-age=300")
        return resp

    # CORS is outermost so 429 responses also carry CORS headers.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_origins),
        allow_methods=["GET", "PUT", "POST"],
        allow_headers=["Authorization", "Content-Type"],
        allow_credentials=False,
    )

    @app.get("/health")
    def health():
        return {"status": "ok", "version": VERSION}

    app.include_router(content.router)
    app.include_router(account.router)
    return app


app = create_app()
