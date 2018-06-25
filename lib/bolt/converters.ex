defmodule Bolt.Converters do
  @moduledoc "Provides interfaces to converts defined in the `Converters` module."

  alias Bolt.Converters.{
    Channel,
    Member,
    Role
  }

  @spec to_member(
          Nostrum.Struct.Snowflake.t(),
          String.t()
        ) :: {:ok, Nostrum.Struct.Guild.Member.t()} | {:error, String.t()}
  def to_member(guild_id, text) do
    Member.member(guild_id, text)
  end

  @spec to_role(
          Nostrum.Struct.Snowflake.t(),
          String.t(),
          boolean()
        ) :: {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
  def to_role(guild_id, text, ilike \\ false) do
    Role.role(guild_id, text, ilike)
  end

  @spec to_channel(
          Nostrum.Struct.Snowflake.t(),
          String.t()
        ) :: {:ok, Nostrum.Struct.Guild.Channel.t()} | {:error, String.t()}
  def to_channel(guild_id, text) do
    Channel.channel(guild_id, text)
  end
end
