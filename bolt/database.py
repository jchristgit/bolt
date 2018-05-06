import asyncio
import os

import peewee
from peewee_async import Manager, PostgresqlDatabase
from playhouse import db_url


engine_url = os.environ['BOLT_DATABASE_URL']
database_config = db_url.parse(engine_url)
database = PostgresqlDatabase(
    database_config['database'],
    user=database_config['user'],
    password=database_config.get('password') or '',
    host=database_config['host']
)
objects = Manager(database, loop=asyncio.get_event_loop())


class Model(peewee.Model):
    class Meta:
        database = database


class EnumField(peewee.CharField):
    def __init__(self, enum, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._enum = enum

    def db_value(self, value):
        return value.name

    def python_value(self, value):
        return self._enum(value)
