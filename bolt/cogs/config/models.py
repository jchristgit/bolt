from sqlalchemy import Table, Column, BigInteger, String, Integer

from bolt.database import metadata

prefix = Table('prefix', metadata,
    Column('guild_id', BigInteger(), primary_key=True),
    Column('prefix', String(50), nullable=False)
)

opt_cog = Table('optional_cog', metadata,
    Column('id', Integer(), primary_key=True),
    Column('name', String(20), nullable=False),
    Column('guild_id', BigInteger(), nullable=False)
)
