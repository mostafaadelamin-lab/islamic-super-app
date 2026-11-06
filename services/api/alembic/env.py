import os

from sqlalchemy import engine_from_config, pool

from alembic import context
from app.db.models import Base

config = context.config
if os.getenv("ISA_DATABASE_URL"):
    config.set_main_option("sqlalchemy.url", os.environ["ISA_DATABASE_URL"])
target_metadata = Base.metadata


def run_migrations_online() -> None:
    engine = engine_from_config(config.get_section(config.config_ini_section), prefix="sqlalchemy.", poolclass=pool.NullPool)
    with engine.connect() as conn:
        context.configure(connection=conn, target_metadata=target_metadata, render_as_batch=True)
        with context.begin_transaction():
            context.run_migrations()


run_migrations_online()
