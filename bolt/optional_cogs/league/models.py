from sqlalchemy import Table, Column, BigInteger, String, Integer

from ...database import metadata


champion = Table('champion', metadata,
    Column('guild_id', BigInteger(), primary_key=True),
    Column('champion_id', Integer(), nullable=False)
)


summoner = Table('summoner', metadata,
    Column('id', BigInteger(), primary_key=True),
    Column('guild_id', BigInteger(), nullable=False, index=True),
    Column('region', String(4), nullable=False)
)
