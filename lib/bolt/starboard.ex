defmodule Bolt.Starboard do
  @moduledoc "Manages configuration and execution of Bolt's Starboard."
  alias Bolt.Constants
  alias Bolt.Repo
  alias Bolt.Schema.{StarboardConfig, StarboardMessage}
  alias Ecto.Changeset
  alias Nostrum.Api
  alias Nostrum.Struct.{Channel, Embed, Guild, Message, User}
  import Ecto.Query, only: [from: 2]

  @doc """
  Configure the starboard for the given guild and channel.
  """
  @spec configure(Guild.id(), Channel.id(), pos_integer()) ::
          {:ok, StarboardConfig.t()} | {:error, Changeset.t()}
  def configure(guild_id, channel_id, min_stars) do
    # If we wanted to be correct here, in the case of
    # a change to `channel_id`, we'd have to delete all
    # messages we sent in the previous starboard channel,
    # as otherwise the bot gets garbled up between channels
    configuration = %{
      guild_id: guild_id,
      channel_id: channel_id,
      min_stars: min_stars
    }

    changeset = StarboardConfig.changeset(%StarboardConfig{}, configuration)
    Repo.insert(changeset, on_conflict: :replace_all, conflict_target: :guild_id)
  end

  @doc """
  Return whether the given channel on the given guild
  is configured as a starboard channel.
  """
  @spec is_starboard_channel?(Guild.id(), Channel.id()) :: boolean()
  def is_starboard_channel?(guild_id, channel_id) do
    query =
      from(sc in StarboardConfig, where: sc.guild_id == ^guild_id and sc.channel_id == ^channel_id)

    Repo.exists?(query)
  end

  @doc """
  Delete all persisted starboard data for the given guild and channel ID
  """
  @spec delete_data(Guild.id(), Channel.id()) :: {non_neg_integer(), non_neg_integer()}
  def delete_data(guild_id, channel_id) do
    config_query =
      from(sc in StarboardConfig, where: sc.guild_id == ^guild_id and sc.channel_id == ^channel_id)

    message_query =
      from(sm in StarboardMessage,
        where: sm.guild_id == ^guild_id and sm.channel_id == ^channel_id
      )

    {deleted_configs, _} = Repo.delete_all(config_query)
    {deleted_messages, _} = Repo.delete_all(message_query)
    {deleted_configs, deleted_messages}
  end

  @doc """
  Create or update the starboard message for the given message & star count in the given starboard channel.
  """
  @spec create_or_update_starboard_message(Channel.id(), Guild.id(), Message.id(), pos_integer()) ::
          any()
  def create_or_update_starboard_message(starboard_channel_id, guild_id, message, star_count) do
    textual_content = "⭐ **#{star_count}** in <##{message.channel_id}>"

    case Repo.get_by(StarboardMessage, guild_id: guild_id, message_id: message.id) do
      %StarboardMessage{starboard_message_id: starboard_message_id} ->
        Api.edit_message(starboard_channel_id, starboard_message_id, textual_content)

      nil ->
        {:ok, created_message} =
          Api.create_message(starboard_channel_id,
            content: textual_content,
            embeds: [starboard_embed_for_message(message)]
          )

        message = %{
          guild_id: guild_id,
          message_id: message.id,
          channel_id: message.channel_id,
          starboard_message_id: created_message.id
        }

        changeset = StarboardMessage.changeset(%StarboardMessage{}, message)
        Repo.insert!(changeset)
    end
  end

  defp starboard_embed_for_message(message) do
    %Embed{
      author: %Embed.Author{
        icon_url: User.avatar_url(message.author),
        name: "#{message.author.username}##{message.author.discriminator}",
        url:
          "https://discord.com/channels/#{message.guild_id}/#{message.channel_id}/#{message.id}"
      },
      color: Constants.color_yellow(),
      description: message.content
    }
    |> maybe_add_image(message)
  end

  defp maybe_add_image(embed, %Message{attachments: [attachment]}) do
    if String.ends_with?(attachment.filename, ".png") do
      Embed.put_image(embed, attachment.url)
    else
      embed
    end
  end

  defp maybe_add_image(embed, _message) do
    embed
  end

  @doc """
  Handle someone adding a star reaction to the given message.
  """
  @spec handle_star_reaction(Guild.id(), Channel.id(), Message.id()) ::
          {:ok, Message.t() | :too_little_stars} | {:error, any() | :no_stars_on_refresh}
  def handle_star_reaction(guild_id, channel_id, message_id) do
    with %StarboardConfig{channel_id: starboard_channel_id, min_stars: min_stars} <-
           Repo.get_by(StarboardConfig, guild_id: guild_id),
         {:ok, message} <- Api.get_channel_message(channel_id, message_id),
         star_reaction when star_reaction != nil <-
           Enum.find(message.reactions, &(&1.emoji.name == "⭐")),
         true <-
           star_reaction.count >=
             min_stars do
      create_or_update_starboard_message(
        starboard_channel_id,
        guild_id,
        message,
        star_reaction.count
      )
    else
      {:error, _reason} = result ->
        result

      nil ->
        {:error, :no_stars_on_refresh}

      false ->
        {:ok, :too_little_stars}
    end
  end
end
