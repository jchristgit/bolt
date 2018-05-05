"""create infraction table

Revision ID: 119cfb34ea90
Revises: c1ab30cefdb5
Create Date: 2018-05-05 22:38:43.543618
"""

from alembic import op
import sqlalchemy as sa

from enum import Enum


# revision identifiers, used by Alembic.
revision = '119cfb34ea90'
down_revision = 'c1ab30cefdb5'
branch_labels = None
depends_on = None


class InfractionType(Enum):
    note = 'note'
    warning = 'warning'
    mute = 'mute'
    kick = 'kick'
    ban = 'ban'


def upgrade():
    op.create_table(
        'infraction',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('guild_id', sa.BigInteger(), nullable=False),
        sa.Column('created_on', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('edited_on', sa.DateTime(), onupdate=sa.func.now()),
        sa.Column('type', sa.Enum(InfractionType), nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('moderator_id', sa.BigInteger(), nullable=False),
        sa.Column('reason', sa.String(250))
    )


def downgrade():
    op.drop_table('infraction')
