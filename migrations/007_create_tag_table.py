"""Peewee migrations -- 007_create_tag_table.py."""

from datetime import datetime

import peewee as pw


class Tag(pw.Model):
    title = pw.CharField(150, index=True)
    content = pw.CharField(2048)
    created_on = pw.DateTimeField(default=datetime.utcnow)
    author_id = pw.BigIntegerField()
    guild_id = pw.BigIntegerField()


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Tag)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('tag')
