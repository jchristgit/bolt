import peewee

from bolt.database import Model


class StaffLogChannel(Model):
    guild_id = peewee.BigIntegerField(primary_key=True)
    channel_id = peewee.BigIntegerField()
    enabled = peewee.BooleanField()
