defmodule Bolt.Cogs.Infraction.User do
  @moduledoc false

  alias Bolt.Cogs.Infraction.General
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.User

  def prepare_for_paginator(msg, {snowflake, maybe_user}) do
    import Ecto.Query, only: [from: 2]

    query = from(i in Infraction, where: [guild_id: ^msg.guild_id, user_id: ^snowflake])
    queryset = Repo.all(query)

    base_embed =
      if maybe_user == nil do
        %Embed{
          title: "infractions for `#{snowflake}`",
          color: Constants.color_blue()
        }
      else
        %Embed{
          title: "infractions for #{User.full_name(maybe_user)}",
          color: Constants.color_blue()
        }
      end

    formatted_entries =
      queryset
      |> Stream.map(fn infr ->
        "[`#{infr.id}`] #{General.emoji_for_type(infr.type)} created #{
          Helpers.datetime_to_human(infr.inserted_at)
        }"
      end)
      |> Stream.chunk_every(6)
      |> Enum.map(fn entry_chunk ->
        %Embed{
          description: Enum.join(entry_chunk, "\n")
        }
      end)

    {base_embed, formatted_entries}
  end
end
