from __future__ import annotations

import json
import time

from fastapi import APIRouter, Depends, HTTPException, Path, Request, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db.models import Bookmark, User, UserSettings
from ..deps import current_user, get_db
from ..schemas import BookmarkIn, BookmarkList, BookmarkOut, Credentials, SettingsIn, SettingsOut, TokenOut, UserOut
from ..security import hash_password, make_token, verify_password

router = APIRouter(prefix="/v1")
ID_RX = r"^[A-Za-z0-9_-]{1,64}$"


def now_ms() -> int:
    return int(time.time() * 1000)


@router.post("/auth/register", status_code=201, response_model=UserOut)
def register(body: Credentials, db: Session = Depends(get_db)):
    email = body.email.lower()
    if db.scalar(select(User).where(func.lower(User.email) == email)):
        raise HTTPException(409, "email already registered")
    u = User(email=email, password_hash=hash_password(body.password))
    db.add(u)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "email already registered") from None
    return UserOut(id=u.id, email=u.email)


@router.post("/auth/login", response_model=TokenOut)
def login(request: Request, body: Credentials, db: Session = Depends(get_db)):
    u = db.scalar(select(User).where(func.lower(User.email) == body.email.lower()))
    if not verify_password(body.password, u.password_hash if u else None) or u is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid email or password")
    s = request.app.state.settings
    return TokenOut(access_token=make_token(u.id, s.jwt_secret, s.jwt_ttl_seconds), expires_in=s.jwt_ttl_seconds)


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(current_user)):
    return UserOut(id=user.id, email=user.email)


@router.get("/me/settings", response_model=SettingsOut)
def get_settings(user: User = Depends(current_user), db: Session = Depends(get_db)):
    row = db.get(UserSettings, user.id)
    return SettingsOut(settings=json.loads(row.data) if row else {}, updatedAt=row.updated_at_ms if row else 0)


@router.put("/me/settings", response_model=SettingsOut)
def put_settings(body: SettingsIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    raw = json.dumps(body.settings, ensure_ascii=False)
    if len(raw) > 8192:
        raise HTTPException(413, "settings too large")
    row = db.get(UserSettings, user.id)
    if row is None:
        row = UserSettings(user_id=user.id, data=raw, updated_at_ms=body.updatedAt)
        db.add(row)
    elif body.updatedAt > row.updated_at_ms:  # last write wins
        row.data, row.updated_at_ms = raw, body.updatedAt
    db.commit()
    return SettingsOut(settings=json.loads(row.data), updatedAt=row.updated_at_ms)


def _out(b: Bookmark) -> BookmarkOut:
    return BookmarkOut(id=b.client_id, surah=b.surah, ayah=b.ayah, note=b.note, updatedAt=b.updated_at_ms, deleted=b.deleted)


@router.get("/bookmarks", response_model=BookmarkList)
def list_bookmarks(since: int = 0, user: User = Depends(current_user), db: Session = Depends(get_db)):
    server_time = now_ms()
    rows = db.scalars(select(Bookmark).where(Bookmark.user_id == user.id, Bookmark.server_seq_ms > since).order_by(Bookmark.server_seq_ms, Bookmark.id)).all()
    return BookmarkList(serverTime=server_time, items=[_out(b) for b in rows])


@router.put("/bookmarks/{bid}", response_model=BookmarkOut)
def put_bookmark(request: Request, body: BookmarkIn, bid: str = Path(pattern=ID_RX), user: User = Depends(current_user), db: Session = Depends(get_db)):
    if body.ayah > request.app.state.quran.ayah_count(body.surah):
        raise HTTPException(422, "ayah number exceeds the surah's ayah count")
    row = db.scalar(select(Bookmark).where(Bookmark.user_id == user.id, Bookmark.client_id == bid))
    if row is None:
        row = Bookmark(
            user_id=user.id,
            client_id=bid,
            surah=body.surah,
            ayah=body.ayah,
            note=body.note,
            deleted=body.deleted,
            updated_at_ms=body.updatedAt,
            server_seq_ms=now_ms(),
        )
        db.add(row)
    elif body.updatedAt > row.updated_at_ms:
        row.surah, row.ayah, row.note, row.deleted = body.surah, body.ayah, body.note, body.deleted
        row.updated_at_ms, row.server_seq_ms = body.updatedAt, now_ms()
    db.commit()
    return _out(row)
