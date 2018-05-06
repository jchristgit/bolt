import asyncio
import os
import peewee
from peewee_async import Manager, PostgresqlDatabase


engine_url = os.environ['BOLT_DATABASE_URL']
database = PostgresqlDatabase(engine_url)
objects = Manager(database, loop=asyncio.get_event_loop())


class Model(peewee.Model):
    class Meta:
        database = database
