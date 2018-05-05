"""create league cog tables

Revision ID: c1ab30cefdb5
Revises: 1a1933fb3ef5
Create Date: 2018-05-05 20:18:01.115423
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c1ab30cefdb5'
down_revision = '1a1933fb3ef5'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'champion',
        sa.Column('guild_id', sa.BigInteger(), primary_key=True),
        sa.Column('champion_id', sa.Integer(), nullable=False)
    )
    op.create_table(
        'summoner',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('guild_id', sa.BigInteger(), nullable=False, index=True),
        sa.Column('region', sa.String(4), nullable=False)
    )
    op.create_table(
        'permitted_role',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('guild_id', sa.BigInteger(), index=True)
    )


def downgrade():
    op.drop_table('champion')
    op.drop_table('summoner')
    op.drop_table('permitted_role')
