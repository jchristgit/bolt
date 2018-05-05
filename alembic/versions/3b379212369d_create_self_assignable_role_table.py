"""create self-assignable role table

Revision ID: 3b379212369d
Revises: 1678e5bb3a23
Create Date: 2018-05-05 19:59:09.546118
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3b379212369d'
down_revision = '1678e5bb3a23'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'self_assignable_role',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('name', sa.String(150), nullable=False),
        sa.Column('guild_id', sa.BigInteger(), nullable=False)
    )


def downgrade():
    op.drop_table('self_assignable_role')
