import inspect

from sqlalchemy import Table, create_engine
from sqlalchemy.engine.reflection import Inspector
from sqlalchemy.schema import CreateTable
from sqlalchemy_aio import ASYNCIO_STRATEGY

from . import models


engine = create_engine(
    'sqlite:///data/bolt.db', strategy=ASYNCIO_STRATEGY
)
inspector = Inspector.from_engine(engine)


async def setup():
    for var_name, table in inspect.getmembers(models, lambda v: isinstance(v, Table)):
        if not await engine.has_table(table.name):
            await engine.execute(CreateTable(table))
