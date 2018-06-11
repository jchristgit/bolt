import logging
import random

from discord import Colour, Embed, Forbidden, Game, Guild, HTTPException
from discord.ext import commands

from .config import CONFIG, get_prefix


log = logging.getLogger(__name__)


class Bot(commands.AutoShardedBot):
    def __init__(self):
        super().__init__(
            command_prefix=get_prefix,
            description=CONFIG['discord']['description'],
            pm_help=None,
            game=Game(name=random.choice(CONFIG['discord']['playing_states']))
        )

    @staticmethod
    def make_error_embed(**kwargs):
        return Embed(colour=Colour.red(), **kwargs)

    async def on_command_error(self, ctx: commands.Context, error: commands.CommandError):
        if isinstance(error, commands.BadArgument):
            error_embed = self.make_error_embed(
                title="Failed to parse command arguments:",
                description=str(error)
            ).set_footer(
                text=f"View `{ctx.prefix}help` for this command for more information."
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.MissingRequiredArgument):
            error_embed = self.make_error_embed(
                title="Missing required command argument",
                description=f"You forgot to specify the `{error.param.name}` argument."
            ).set_footer(
                text=f"View `{ctx.prefix}help` for this command for more information."
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.NoPrivateMessage):
            error_embed = self.make_error_embed(
                title="This command cannot be used in private messages."
            )
            error_description = str(error)
            if error_description:
                error_embed.description = error_description
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.NotOwner):
            error_embed = self.make_error_embed(
                description=f"{ctx.author.mention} is not in the sudoers file. "
                            "This incident will be reported."
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.MissingPermissions):
            error_embed = self.make_error_embed(
                title="You don't have the necessary permissions to do that.",
                description="You lack the following permissions: "
                            ', '.join(f"`{perm}`" for perm in error.missing_perms)
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.BotMissingPermissions):
            error_embed = self.make_error_embed(
                title="I don't have the necessary permissions to do that.",
                description="I lack the following permissions: "
                            ', '.join(f"`{perm}`" for perm in error.missing_perms)
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.CheckFailure):
            error_embed = self.make_error_embed(
                title="A required check for this command did not pass.",
                description=str(error) or "You're probably not allowed to do that."
            )
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.CommandOnCooldown):
            await ctx.message.add_reaction('⏳')

        elif isinstance(error, commands.TooManyArguments):
            error_embed = self.make_error_embed(
                title="You gave me more arguments than I expected.",
            ).set_footer(
                text=f"View `{ctx.prefix}help` for this command for more information."
            )

            error_string = str(error)
            if error_string:
                error_embed.description = error_string
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.DisabledCommand):
            error_embed = self.make_error_embed(title="Sorry, this command is currently disabled.")
            await ctx.send(embed=error_embed)

        elif isinstance(error, commands.CommandInvokeError):
            if isinstance(error.original, Forbidden):
                original_description = str(error.original)
                if "Cannot send messages to this user" in original_description:
                    error_embed = self.make_error_embed(
                        title="I tried to send a PM, but you said 'no, no, no'",
                        description="Please allow server members to send you direct "
                                    "messages as this is required by the command."
                    )
                    await ctx.send(embed=error_embed)

                else:
                    error_embed = self.make_error_embed(
                        title="I'm not allowed to do that.",
                        description=(original_description
                                     or "Does the Bot have the appropriate permissions?")
                    )
                    await ctx.send(embed=error_embed)

            elif isinstance(error.original, HTTPException):
                error_embed = self.make_error_embed(
                    title=f"Got status `{error.original.status}`",
                    description="Something went wrong and the Discord API "
                                "didn't allow me to do what I wanted to."
                )
                await ctx.send(error_embed)
                log.error(f"Encountered a command error for message {ctx.message.content}")
                await super().on_command_error(ctx, error)

            else:
                error_embed = self.make_error_embed(
                    title=f"Got some weird error that I don't understand",
                    description="Worry not, the bot administrator has been informed."
                )
                await ctx.send(embed=error_embed)
                log.error(f"Encountered a command error for message {ctx.message.content!r}")
                await super().on_command_error(ctx, error)
        else:
            log.error(f"Unhandled command error (from message {ctx.message.content!r})")
            await super().on_command_error(ctx, error)

    async def on_ready(self):
        log.info("Logged in.")

    async def on_message(self, msg):
        if msg.author.bot:
            return

        await self.process_commands(msg)

    async def send_stafflog(self, guild: Guild, contents: Embed):
        cog = self.get_cog('StaffLog')
        if cog is not None:
            await cog.log_for(guild, contents)
