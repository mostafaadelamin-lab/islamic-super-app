"""Alembic migrations must produce exactly the schema the ORM models describe, and be reversible."""

import subprocess
import sys

from sqlalchemy import create_engine, inspect

from app.db.models import Base

from .conftest import REPO

API = REPO / "services/api"


def alembic(*args, url):
    return subprocess.run(
        [sys.executable, "-m", "alembic", *args], cwd=API, env={"ISA_DATABASE_URL": url, "PATH": ""}, capture_output=True, text=True, check=True
    )


def test_upgrade_matches_models_and_downgrade_is_clean(tmp_path):
    url = f"sqlite:///{tmp_path / 'm.db'}"
    alembic("upgrade", "head", url=url)
    insp = inspect(create_engine(url))
    tables = set(insp.get_table_names()) - {"alembic_version"}
    assert tables == set(Base.metadata.tables)
    for name, table in Base.metadata.tables.items():
        assert {c["name"] for c in insp.get_columns(name)} == {c.name for c in table.columns}, name
    assert any(u["column_names"] == ["user_id", "client_id"] for u in insp.get_unique_constraints("bookmarks"))
    alembic("downgrade", "base", url=url)
    assert set(inspect(create_engine(url)).get_table_names()) <= {"alembic_version"}


def test_cascade_delete_user_removes_bookmarks(client, auth):
    h = auth("c@example.com")
    client.put("/v1/bookmarks/b", json={"surah": 1, "ayah": 1, "updatedAt": 1}, headers=h)
    from app.db.models import Bookmark, User

    with client.app.state.db.factory() as s:
        s.delete(s.query(User).filter_by(email="c@example.com").one())
        s.commit()
        assert s.query(Bookmark).count() == 0
