from __future__ import annotations

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class Credentials(BaseModel):
    model_config = ConfigDict(extra="forbid")
    email: EmailStr
    password: str = Field(min_length=10, max_length=256)


class UserOut(BaseModel):
    id: int
    email: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class BookmarkIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    surah: int = Field(ge=1, le=114)
    ayah: int = Field(ge=1, le=286)
    note: str | None = Field(default=None, max_length=500)
    updatedAt: int = Field(ge=0, le=10**14)
    deleted: bool = False


class BookmarkOut(BookmarkIn):
    id: str


class BookmarkList(BaseModel):
    serverTime: int
    items: list[BookmarkOut]


class SettingsIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    settings: dict = Field(default_factory=dict)
    updatedAt: int = Field(ge=0, le=10**14)


class SettingsOut(SettingsIn):
    pass
