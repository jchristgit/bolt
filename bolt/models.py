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
    Column('creation', DateTime(), default=datetime.utcnow()),
    Column('author_id', BigInteger(), nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)