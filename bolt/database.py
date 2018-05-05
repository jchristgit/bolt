from sqlalchemy import create_engine, MetaData
from sqlalchemy_aio import ASYNCIO_STRATEGY


engine = create_engine(
    'sqlite:///data/bolt.db', strategy=ASYNCIO_STRATEGY
)
metadata = MetaData()
