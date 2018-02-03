from sqlalchemy import Table, Column, BigInteger, String

from bolt.database import metadata

sar = Table('self_assignable_role', metadata,
    Column('id', BigInteger(), primary_key=True),
    Column('name', String(150), index=True, nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)