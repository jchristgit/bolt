"""create mute tables

Revision ID: 7ae8548e384c
Revises: 119cfb34ea90
Create Date: 2018-05-06 01:55:34.268553
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '7ae8548e384c'
down_revision = '119cfb34ea90'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'mute',
        sa.Column('expiry', sa.DateTime()),
        sa.Column('active', sa.Boolean(), default=True),
        sa.Column('infraction_id', sa.Integer(), sa.ForeignKey('infraction.id', ondelete='CASCADE'), primary_key=True)
    )
    op.create_table(
        'mute_role',
        sa.Column('guild_id', sa.BigInteger(), primary_key=True),
        sa.Column('role_id', sa.BigInteger(), primary_key=True)
    )


def downgrade():
    op.drop_table('mute')
    op.drop_table('mute_role')
