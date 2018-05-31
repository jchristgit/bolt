"""Peewee migrations -- 011_make_edited_on_null_without_edits.py."""


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.drop_not_null('infraction', 'edited_on')


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.add_not_null('infraction', 'edited_on')
