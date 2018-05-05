"""create tag table

Revision ID: 1a1933fb3ef5
Revises: 3b379212369d
Create Date: 2018-05-05 20:01:02.756354
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '1a1933fb3ef5'
down_revision = '3b379212369d'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'tag',
        sa.Column('title', sa.String(150), primary_key=True),
        sa.Column('guild_id', sa.BigInteger(), primary_key=True),
        sa.Column('author_id', sa.BigInteger(), nullable=False),
        sa.Column('content', sa.String(2048), nullable=False),
        sa.Column('created_on', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('edited_on', sa.DateTime(), server_onupdate=sa.func.now())
    )


def downgrade():
    op.drop_table('tag')
