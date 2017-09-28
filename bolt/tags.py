import datetime

import dataset
import discord
from discord.ext import commands
from stuf import stuf


guild_db = dataset.connect('sqlite:///data/guilds.db', row_type=stuf)


class Tags:
    """Commands for creating, editing, and reading Tags."""

    def __init__(self, bot):
        self.bot = bot
        self._tag_table = guild_db['tag']

    @staticmethod
    def __unload():
        print("Unloaded Cog Tags.")

    @commands.group(invoke_without_command=True)
    @commands.guild_only()
    async def tag(self, ctx, *, tag_name: str):
        """Sub-commands for managing and using tags.

        To view a tag, simply use this command along with a tag name.
        """

        tag = self._tag_table.find_one(guild_id=ctx.guild.id, name=tag_name)
        if tag is None:
            await ctx.send(embed=discord.Embed(
                title=f"No tag named {tag_name!r} found.",
                colour=discord.Colour.red()
            ))
        else:
            tag_embed = discord.Embed(
                title=tag_name,
                colour=discord.Colour.blue(),
                description=tag.content
            )
            author = self.bot.get_user(tag.author_id)
            if author is not None:
                tag_embed.set_footer(
                    text=f"Created by {author.name}",
                    icon_url=author.avatar_url
                )
            else:
                tag_embed.set_footer(
                    text=f"Created by {tag.author_id}"
                )
            await ctx.send(embed=tag_embed)

    @tag.command()
    @commands.guild_only()
    async def create(self, ctx, tag_name: str, *, tag_content: str):
        """Create a new tag.

        The tag will only be usable in the Guild on which it was created.
        The author as well as moderators with the manage message permission
        on the guild can remove a tag that they do not own.

        To give the tag a name spanning muliple words, enclose it in quotes:
            tag create 'my tag name' tag content
        """

        if self._tag_table.find_one(guild_id=ctx.guild.id,
                                    tag_content=tag_content) is not None:
            await ctx.send(embed=discord.Embed(
                title="A Tag with the given contents already exists.",
                colour=discord.Colour.red()
            ))
        else:
            self._tag_table.insert(dict(
                guild_id=ctx.guild.id,
                author_id=ctx.message.author.id,
                name=tag_name,
                content=tag_content,
                created_on=datetime.datetime.utcnow()
            ))
            await ctx.send(embed=discord.Embed(
                title=f"Created the tag {tag_name!r}!",
                colour=discord.Colour.green()
            ))


def setup(bot):
    bot.add_cog(Tags(bot))
