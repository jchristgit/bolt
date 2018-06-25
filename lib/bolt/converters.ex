defmodule Bolt.Converters do
  @moduledoc "Provides interfaces to converts defined in the `Converters` module."

  alias Bolt.Converters.{
    Channel,
    Member,
    Role
  }

  def to_member(guild_id, text) do
    Member.member(guild_id, text)
  end

  def to_role(guild_id, text, ilike \\ false) do
    Role.role(guild_id, text, ilike)
  end

  def to_channel(guild_id, text) do
    Channel.channel(guild_id, text)
  end
end
