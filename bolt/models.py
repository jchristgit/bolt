from datetime import datetime

from sqlalchemy import (
    Table, Column, MetaData,
    Integer, String, DateTime, BigInteger
)


metadata = MetaData()


tag = Table('tag', metadata,
    Column('id', Integer(), primary_key=True),
    Column('title', String(150), index=True, nullable=False, unique=True),
    Column('content', String(2048), nullable=False),
    Column('created_on', DateTime(), default=datetime.utcnow),
    Column('author_id', BigInteger(), nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)


sar = Table('self_assignable_role', metadata,
    Column('id', BigInteger(), primary_key=True),
    Column('name', String(150), index=True, nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)


prefix = Table('prefix', metadata,
    Column('guild_id', BigInteger(), primary_key=True),
    Column('prefix', String(50), nullable=False)
)


opt_cog = Table('optional_cog', metadata,
    Column('id', Integer(), primary_key=True),
    Column('name', String(20), nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)
