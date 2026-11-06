"""initial schema: users, user_settings, bookmarks

Revision ID: 0001
Revises:
"""

import sqlalchemy as sa

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_table(
        "user_settings",
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("data", sa.Text, nullable=False),
        sa.Column("updated_at_ms", sa.BigInteger, nullable=False),
    )
    op.create_table(
        "bookmarks",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("client_id", sa.String(64), nullable=False),
        sa.Column("surah", sa.Integer, nullable=False),
        sa.Column("ayah", sa.Integer, nullable=False),
        sa.Column("note", sa.String(500), nullable=True),
        sa.Column("deleted", sa.Boolean, nullable=False),
        sa.Column("updated_at_ms", sa.BigInteger, nullable=False),
        sa.Column("server_seq_ms", sa.BigInteger, nullable=False),
        sa.UniqueConstraint("user_id", "client_id", name="uq_bookmark_user_client"),
    )
    op.create_index("ix_bookmarks_user_id", "bookmarks", ["user_id"])
    op.create_index("ix_bookmarks_updated_at_ms", "bookmarks", ["updated_at_ms"])
    op.create_index("ix_bookmarks_server_seq_ms", "bookmarks", ["server_seq_ms"])


def downgrade() -> None:
    op.drop_table("bookmarks")
    op.drop_table("user_settings")
    op.drop_index("ix_users_email", "users")
    op.drop_table("users")
