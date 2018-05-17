from discord.ext.commands import BadArgument, Converter


class TagName(Converter):
    """A converter for validating tag names on tag subcommands.

    Used on the `tag create` command to ensure that users
    can not create tag names
    """

    async def convert(self, ctx, tag_name: str):
        tag_subcommands = ctx.command.parent.commands
        if tag_name in (subcommand.name for subcommand in tag_subcommands):
            raise BadArgument("The tag name must not be the name of a tag subcommand.")
        elif any(tag_name in subcommand.aliases for subcommand in tag_subcommands):
            raise BadArgument("The tag name must not be the alias of a tag subcommand.")

        return tag_name
