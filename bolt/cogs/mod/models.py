from sqlalchemy import BigInteger, Column, DateTime, Enum, func, String, Table

from .types import InfractionType
from ...database import metadata


infraction = Table('infraction', metadata,
    Column('id', BigInteger(), primary_key=True),
    Column('created_on', DateTime(), server_default=func.now()),
    Column('edited_on', DateTime(), server_onupdate=func.now()),
    Column('type', Enum(InfractionType), nullable=False),
    Column('user_id', BigInteger(), nullable=False),
    Column('moderator_id', BigInteger(), nullable=False),
    Column('reason', String(250))
)
