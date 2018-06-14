defmodule Bolt.Converters do
  alias Bolt.Converters.{
    Member,
    Role
  }

  def to_member(guild_id, text) do
    Member.member(guild_id, text)
  end

  def to_role(guild_id, text, ilike \\ false) do
    Role.role(guild_id, text, ilike)
  end
end
