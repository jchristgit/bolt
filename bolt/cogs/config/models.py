import peewee

from ...database import Model


class Prefix(Model):
    guild_id = peewee.BigIntegerField(primary_key=True)
    prefix = peewee.CharField(max_length=25)


class OptionalCog(Model):
    name = peewee.CharField(max_length=20)
    guild_id = peewee.BigIntegerField()
