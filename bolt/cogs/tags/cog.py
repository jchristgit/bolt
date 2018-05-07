import logging

import discord
import peewee_async
from discord.ext import commands
from peewee import DoesNotExist

from bolt.database import objects
from .models import Tag


log = logging.getLogger(__name__)


class Tags:
    """Commands for creating, editing, and reading Tags."""

    def __init__(self, bot):
        self.bot = bot
        log.debug("Loaded Cog Tags.")

    @staticmethod
    def __unload():
        log.debug("Unloaded Cog Tags.")

    async def get_exact_match(self, tag_title: str, guild_id: int):
        try:
            return await objects.get(
                Tag,
                Tag.title ** tag_title,
                Tag.guild_id == guild_id
            )
        except DoesNotExist:
            return None

    @commands.group(invoke_without_command=True)
    @commands.guild_only()
    async def tag(self, ctx, *, tag_name: str):
        """Sub-commands for managing and using tags.

        To view a tag, simply use this command along with a tag name.
        """

        match = await self.get_exact_match(tag_name, ctx.guild.id)

        if match is None:
            tag = await self.get_exact_match(f'%{tag_name}%', ctx.guild.id)

            if tag is None:
                return await ctx.send(embed=discord.Embed(
                    title=f"No tag with a similar name to {tag_name!r} found.",
                    colour=discord.Colour.red()
                ))
            match = tag

        tag_embed = discord.Embed(
            title=f"{match.title} (from {tag_name!r})",
            colour=discord.Colour.blue(),
            description=match.content,
            timestamp=match.created_on
        )

        author = self.bot.get_user(match.author_id)
        if author is not None:
            tag_embed.set_footer(
                text=f"Created by {author.name}",
                icon_url=author.avatar_url
            )
        else:
            tag_embed.set_footer(
                text=f"Created by {match.author_id}"
            )
        await ctx.send(embed=tag_embed)

    @tag.command()
    @commands.guild_only()
    async def create(self, ctx, tag_title: str, *, tag_content: str):
        """Create a new tag.

        The tag will only be usable in the Guild on which it was created.
        The author as well as moderators with the manage message permission
        on the guild can remove a tag that they do not own.

        To give the tag a name spanning multiple words, enclose it in quotes:
            tag create 'my tag name' tag content
        """

        _, created = await objects.get_or_create(
            Tag,
            title=tag_title,
            defaults={
                'content': tag_content,
                'author_id': ctx.author.id,
                'guild_id': ctx.guild.id
            }
        )

        if created:
            await ctx.send(embed=discord.Embed(
                title=f"Created the tag {tag_title!r}!",
                colour=discord.Colour.green()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title="A Tag with the given name already exists.",
                colour=discord.Colour.red()
            ))

    @tag.command(aliases=("del", "rm"))
    @commands.guild_only()
    async def delete(self, ctx, *, tag_title: str):
        """Delete the specified tag.

        The tag needs to be created on the guild this is
        invoked, and the author needs to either have the
        'manage messages' permission or should be the
        original creator of the tag.

        Unlike with querying for a tag through the `tag`
        command, this command requires the full tag to
        ensure that the correct tag is deleted, with the
        exceptions that it is case-insensitive.
        """

        tag = await self.get_exact_match(tag_title, ctx.guild.id)

        if tag is not None:
            if (ctx.author.id == tag.author_id
               or ctx.author.permissions_in(ctx.channel).manage_messages):
                await objects.delete(tag)
                await ctx.send(embed=discord.Embed(
                    title=f"Deleted the tag {tag_title!r}.",
                    colour=discord.Colour.green()
                ))
            else:
                await ctx.send(embed=discord.Embed(
                    title="Not allowed to delete tag",
                    description=("You need to either have the 'Manage "
                                 "Messages' permission or need to be "
                                 "the creator of the specified tag."),
                    colour=discord.Colour.red()
                ))
        else:
            await ctx.send(embed=discord.Embed(
                title="Failed to delete tag",
                description=f"No tag named {tag_title!r} found on this Guild.",
                colour=discord.Colour.red()
            ))

    @tag.command(aliases=("all",), name="list")
    @commands.guild_only()
    async def list_(self, ctx):
        """Lists all tags on the guild."""

        guild_tags = await peewee_async.execute(
            Tag.select()
               .where(Tag.guild_id == ctx.guild.id)
        )

        await ctx.send(embed=discord.Embed(
            title=f"Tags on {ctx.guild.name}:",
            description=', '.join(repr(t.title) for t in guild_tags) or 'This guild has no tags.',
            colour=discord.Color.blue()
        ))
