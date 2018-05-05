"""create prefix table

Revision ID: fe100086c737
Revises:
Create Date: 2018-05-05 19:55:20.507973
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'fe100086c737'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'prefix',
        sa.Column('guild_id', sa.BigInteger(), primary_key=True),
        sa.Column('prefix', sa.String(50), nullable=False)
    )


def downgrade():
    op.drop_table('prefix')
