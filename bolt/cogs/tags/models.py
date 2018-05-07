from datetime import datetime

import peewee

from bolt.database import Model


class Tag(Model):
    title = peewee.CharField(150, index=True)
    content = peewee.CharField(2048)
    created_on = peewee.DateTimeField(default=datetime.utcnow)
    author_id = peewee.BigIntegerField()
    guild_id = peewee.BigIntegerField()
