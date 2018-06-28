defmodule Bolt.Cogs.Infraction.List do
  @moduledoc false

  alias Bolt.Cogs.Infraction.General
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.Embed

  @spec prepare_for_paginator(
          Nostrum.Struct.Message.t(),
          String.t()
        ) :: {Embed.t(), [Embed.t()]}
  def prepare_for_paginator(msg, maybe_type) do
    import Ecto.Query, only: [from: 2]

    {title, queryset} =
      case General.emoji_for_type(maybe_type) do
        "?" ->
          query =
            from(
              infr in Infraction,
              where: infr.guild_id == ^msg.guild_id,
              order_by: [desc: infr.inserted_at],
              select: infr
            )

          {"All infractions on this guild", Repo.all(query)}

        valid_type ->
          query =
            from(
              infr in Infraction,
              where: [guild_id: ^msg.guild_id, type: ^valid_type],
              order_by: [desc: infr.inserted_at],
              select: infr
            )

          {"Infractions with type `#{valid_type}` on this guild", Repo.all(query)}
      end

    base_embed = %Embed{
      title: title,
      color: Constants.color_blue()
    }

    formatted_entries =
      queryset
      |> Stream.map(fn infr ->
        "[`#{infr.id}`] #{General.emoji_for_type(infr.type)} on " <>
          "#{General.format_user(msg.guild_id, infr.user_id)} created #{
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
