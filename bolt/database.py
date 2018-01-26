from sqlalchemy import create_engine
from sqlalchemy_aio import ASYNCIO_STRATEGY

from . import models
from .models import metadata


engine = create_engine(
    'sqlite:///data/guilds.db', strategy=ASYNCIO_STRATEGY
)
metadata.create_all(engine)
