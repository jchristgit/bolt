import peewee

from ...database import Model


class SelfAssignableRole(Model):
    id = peewee.BigIntegerField(primary_key=True)
    name = peewee.CharField(150)
    guild_id = peewee.BigIntegerField()
