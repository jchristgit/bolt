"""create optional cog table

Revision ID: 1678e5bb3a23
Revises: fe100086c737
Create Date: 2018-05-05 19:57:28.977196
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '1678e5bb3a23'
down_revision = 'fe100086c737'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'optional_cog',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(20), nullable=False),
        sa.Column('guild_id', sa.BigInteger(), nullable=False)
    )


def downgrade():
    op.drop_table('optional_cog')
