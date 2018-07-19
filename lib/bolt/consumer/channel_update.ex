defmodule Bolt.Consumer.ChannelUpdate do
  @moduledoc "Handles the `CHANNEL_UPDATE` event."

  alias Bolt.{Helpers, ModLog}
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.{Channel, Guild, Overwrite, Permission, User}

  @spec handle(Channel.t(), Channel.t()) :: ModLog.on_emit()
  def handle(old_channel, new_channel) do
    unless new_channel.guild_id == nil do
      diff_string =
        []
        |> describe_changes_if_present(old_channel, new_channel, :name)
        |> describe_changes_if_present(old_channel, new_channel, :topic)
        |> describe_changes_if_present(old_channel, new_channel, :parent_id)
        |> describe_changes_if_present(old_channel, new_channel, :nsfw)
        |> describe_changes_if_present(old_channel, new_channel, :permission_overwrites)
        |> describe_changes_if_present(old_channel, new_channel, :position)
        |> describe_changes_if_present(old_channel, new_channel, :bitrate)
        |> describe_changes_if_present(old_channel, new_channel, :user_limit)
        |> Enum.join(", ")

      type_string =
        case new_channel.type do
          0 -> "text channel"
          2 -> "voice channel"
          4 -> "channel category"
          _ -> "unknown channel type"
        end

      ModLog.emit(
        new_channel.guild_id,
        "CHANNEL_UPDATE",
        "#{type_string} #{Channel.mention(new_channel)} (`#{new_channel.id}`) #{diff_string}"
      )
    end
  end

  @spec describe_changes_if_present([String.t()], Channel.t(), Channel.t(), atom()) :: [
          String.t()
        ]
  def describe_changes_if_present(diff_list, old_channel, new_channel, key) do
    if Map.has_key?(new_channel, key) do
      describe_changes(diff_list, old_channel, new_channel, key)
    else
      diff_list
    end
  end

  @spec describe_changes([String.t()], Channel.t(), Channel.t(), atom()) :: [String.t()]
  def describe_changes(diff_list, old_channel, new_channel, :permission_overwrites) do
    myers_difference =
      List.myers_difference(
        old_channel.permission_overwrites,
        new_channel.permission_overwrites
      )

    added_overwrites = Keyword.get_values(myers_difference, :ins) |> List.flatten()
    removed_overwrites = Keyword.get_values(myers_difference, :del) |> List.flatten()

    diff_list ++
      Enum.map(
        removed_overwrites,
        &"overwrite removed for #{format_overwrite(new_channel.guild_id, &1)}"
      ) ++
      Enum.map(
        added_overwrites,
        &"overwrite added for #{format_overwrite(new_channel.guild_id, &1)}"
      )
  end

  def describe_changes(diff_list, old_channel, new_channel, key) do
    old_value = Map.get(old_channel, key) |> IO.inspect(label: "old value")
    new_value = Map.get(new_channel, key) |> IO.inspect(label: "new value")

    if old_value != new_value do
      cond do
        new_value === true ->
          diff_list ++ ["now #{key}"]

        new_value === false ->
          diff_list ++ ["no longer #{key}"]

        old_value == "" ->
          diff_list ++ ["#{key} added ``#{Helpers.clean_content(new_value)}``"]

        new_value == "" ->
          diff_list ++ ["#{key} removed (was ``#{Helpers.clean_content(old_value)}``)"]

        is_bitstring(old_value) and is_bitstring(new_value) ->
          diff_list ++
            [
              "#{key} updated from ``#{Helpers.clean_content(old_value)}`` " <>
                "to ``#{Helpers.clean_content(new_value)}``"
            ]

        true ->
          diff_list ++ ["#{key} updated from ``#{old_value}`` to ``#{new_value}``"]
      end
    else
      diff_list
    end
  end

  @spec format_overwrite(Guild.id(), Overwrite.t()) :: String.t()
  def format_overwrite(guild_id, overwrite) do
    base_string =
      if overwrite.name == "role" do
        with {:ok, guild} <- GuildCache.get(guild_id),
             role when role != nil <- Enum.find(guild.roles, &(&1.id == overwrite.id)) do
          "role #{Helpers.clean_content(role.name)} (`#{role.id}`)"
        else
          _err -> "role `#{overwrite.id}`"
        end
      else
        with {:ok, guild} <- GuildCache.get(guild_id),
             member when member != nil <- Enum.find(guild.members, &(&1.user.id == overwrite.id)) do
          "user #{Helpers.clean_content(User.full_name(member.user))} (`#{member.user.id}`)"
        else
          _err -> "user `#{overwrite.id}`"
        end
      end

    "#{base_string} for " <>
      "#{
        overwrite.allow |> Permission.from_bitset!() |> Enum.map(&"can #{&1}") |> Enum.join(", ")
      }" <>
      "#{
        overwrite.deny
        |> Permission.from_bitset!()
        |> Enum.map(&"can not #{&1}")
        |> Enum.join(", ")
      }"
  end
end
