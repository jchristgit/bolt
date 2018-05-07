import peewee

from bolt.database import Model


class Champion(Model):
    id = peewee.IntegerField()
    guild_id = peewee.BigIntegerField(primary_key=True)


class Summoner(Model):
    id = peewee.BigIntegerField(primary_key=True)
    guild_id = peewee.BigIntegerField()
    region = peewee.FixedCharField(4)


class PermittedRole(Model):
    id = peewee.BigIntegerField()
    guild_id = peewee.BigIntegerField()

    class Meta:
        primary_key = peewee.CompositeKey('id', 'guild_id')
