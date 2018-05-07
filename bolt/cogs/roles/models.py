import peewee

from bolt.database import Model


class SelfAssignableRole(Model):
    id = peewee.BigIntegerField(primary_key=True)
    name = peewee.CharField(150)
    guild_id = peewee.BigIntegerField()
