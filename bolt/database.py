import inspect
import itertools

from sqlalchemy import Table, create_engine, MetaData
from sqlalchemy.schema import CreateTable
from sqlalchemy_aio import ASYNCIO_STRATEGY

from . import cogs, optional_cogs


engine = create_engine(
    'sqlite:///data/bolt.db', strategy=ASYNCIO_STRATEGY
)
metadata = MetaData()


def get_cog_models():
    for _, cog_pkg in itertools.chain(
            inspect.getmembers(cogs, inspect.ismodule),
            inspect.getmembers(optional_cogs, inspect.ismodule)):
        for name, cog_module in inspect.getmembers(cog_pkg, inspect.ismodule):
            if name == 'models':
                for _, table in inspect.getmembers(cog_module, lambda v: isinstance(v, Table)):
                    yield table


async def setup():
    for table in get_cog_models():
        if not await engine.has_table(table.name):
            await engine.execute(CreateTable(table))
