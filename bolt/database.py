import os


from sqlalchemy import create_engine, MetaData
from sqlalchemy_aio import ASYNCIO_STRATEGY


engine_url = os.environ['BOLT_DATABASE_URL']
engine = create_engine(
    engine_url, strategy=ASYNCIO_STRATEGY
)
metadata = MetaData()
