from sqlalchemy import BigInteger, Boolean, Column, DateTime, Enum, ForeignKey, func, Integer, String, Table

from .types import InfractionType
from ...database import metadata


infraction = Table('infraction', metadata,
    Column('id', Integer(), primary_key=True),
    Column('guild_id', BigInteger(), nullable=False),
    Column('created_on', DateTime(), server_default=func.now()),
    Column('edited_on', DateTime(), onupdate=func.now()),
    Column('type', Enum(InfractionType), nullable=False),
    Column('user_id', BigInteger(), nullable=False),
    Column('moderator_id', BigInteger(), nullable=False),
    Column('reason', String(250))
)


mute = Table('mute', metadata,
    Column('expiry', DateTime()),
    Column('active', Boolean(), default=True),
    Column('infraction_id', Integer(), ForeignKey(infraction.c.id, ondelete='CASCADE'), primary_key=True)
)


mute_role = Table('mute_role', metadata,
    Column('guild_id', BigInteger(), primary_key=True),
    Column('role_id', BigInteger(), primary_key=True)
)
