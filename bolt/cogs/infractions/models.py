from datetime import datetime

import peewee

from bolt.database import EnumField, Model
from .types import InfractionType


class Infraction(Model):
    guild_id = peewee.BigIntegerField()
    created_on = peewee.DateTimeField(default=datetime.utcnow)
    edited_on = peewee.DateTimeField(default=None, null=True)  # ON UPDATE handled through trigger
    type = EnumField(InfractionType)
    user_id = peewee.BigIntegerField()
    moderator_id = peewee.BigIntegerField()
    reason = peewee.CharField(max_length=250, null=True)
