defmodule Bolt.Consumer.ChannelUpdate do
  @moduledoc "Handles the `CHANNEL_UPDATE` event."

  alias Bolt.{Helpers, Humanizer, ModLog}
  alias Nostrum.Permission
  alias Nostrum.Struct.{Channel, Guild, Overwrite}
  require Logger

  @spec handle(Channel.t(), Channel.t()) :: ModLog.on_emit()
  def handle(old_channel, new_channel) do
    unless new_channel.guild_id == nil do
      diff_string =
        []
        |> describe_changes(old_channel, new_channel, :name)
        |> describe_changes(old_channel, new_channel, :topic)
        |> describe_changes(old_channel, new_channel, :parent_id)
        |> describe_changes(old_channel, new_channel, :nsfw)
        |> describe_changes(old_channel, new_channel, :permission_overwrites)
        |> describe_changes(old_channel, new_channel, :bitrate)
        |> describe_changes(old_channel, new_channel, :user_limit)
        |> Enum.join(", ")

      type_string =
        case new_channel.type do
          0 -> "text channel"
          2 -> "voice channel"
          4 -> "channel category"
          _ -> "unknown channel type"
        end

      unless diff_string == "" do
        ModLog.emit(
          new_channel.guild_id,
          "CHANNEL_UPDATE",
          "#{type_string} #{Channel.mention(new_channel)} (`#{new_channel.id}`) #{diff_string}"
        )
      end
    end
  rescue
    err ->
      Logger.warning("Encountered channel update error for:")
      Logger.warning("Old channel: #{inspect(old_channel)}")
      Logger.warning("New channel: #{inspect(new_channel)}")
      Logger.error(Exception.format(:error, err, __STACKTRACE__))
      reraise err, __STACKTRACE__
  end

  @spec describe_changes([String.t()], Channel.t(), Channel.t(), atom()) :: [String.t()]
  defp describe_changes(diff_list, old_channel, new_channel, :permission_overwrites) do
    # The overwrite difference calculation algorithm is fairly expensive, so let's only
    # actually run it if the permission overwrites of the given channel actually changed.
    if old_channel.permission_overwrites != new_channel.permission_overwrites do
      myers_difference =
        List.myers_difference(
          old_channel.permission_overwrites,
          new_channel.permission_overwrites
        )

      added_overwrites = myers_difference |> Keyword.get_values(:ins) |> List.flatten()
      removed_overwrites = myers_difference |> Keyword.get_values(:del) |> List.flatten()

      diff_list ++ describe_overwrites(new_channel.guild_id, added_overwrites, removed_overwrites)
    else
      diff_list
    end
  end

  # Describe what changed for this channel, if different.
  # credo:disable-for-next-line
  defp describe_changes(diff_list, old_channel, new_channel, key) do
    old_value = Map.get(old_channel, key)
    new_value = Map.get(new_channel, key)

    cond do
      old_value == new_value ->
        diff_list

      new_value == "" and old_value == nil ->
        # I Love Types!
        diff_list

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
  end

  # Describe the difference between `added_overwrites`
  # and `removed_overwrites` in a human-friendly way.
  @spec describe_overwrites(
          Guild.id(),
          [Overwrite.t()],
          [Overwrite.t()]
        ) :: [String.t()]
  defp describe_overwrites(guild_id, added_overwrites, removed_overwrites) do
    # First, we build a map of the IDs of all overwrites.
    possible_keys = Enum.map(added_overwrites, & &1.id) ++ Enum.map(removed_overwrites, & &1.id)

    id_mapping =
      Enum.reduce(
        possible_keys,
        %{},
        fn key, mapping -> Map.put(mapping, key, {nil, nil}) end
      )

    # Now, we add any removed overwrite as the first value in the `{before, after}` tuple.
    id_mapping =
      Enum.reduce(
        removed_overwrites,
        id_mapping,
        fn overwrite, mapping -> Map.put(mapping, overwrite.id, {overwrite, nil}) end
      )

    # Finally, we add the added overwrite as the second value in the `{before, after}` tuple.
    added_overwrites
    |> Enum.reduce(
      id_mapping,
      fn overwrite, mapping ->
        {_, new_map} =
          Map.get_and_update(
            mapping,
            overwrite.id,
            fn current_value -> {current_value, {elem(current_value, 0), overwrite}} end
          )

        new_map
      end
    )
    |> Map.values()
    |> Stream.map(&format_overwrite_diff(guild_id, &1))
    |> Enum.reject(&(&1 == ""))
  end

  # Describes the difference between two overwrites.
  @spec format_overwrite_diff(
          Guild.id(),
          {old_overwrite :: Overwrite.t() | nil, new_overwrite :: Overwrite.t() | nil}
        ) :: String.t()
  def format_overwrite_diff(guild_id, {nil, new_overwrite}) do
    # A new overwrite was created.
    # Describe which overwrites were added and which were removed.
    added_permissions = Permission.from_bitset(new_overwrite.allow)
    removed_permissions = Permission.from_bitset(new_overwrite.deny)

    "added overwrite for #{format_overwrite_target(guild_id, new_overwrite)}, " <>
      Enum.join(
        Enum.map(
          added_permissions,
          &"now allowed to `#{&1}`"
        ) ++
          Enum.map(
            removed_permissions,
            &"no longer allowed to `#{&1}`"
          ),
        ", "
      )
  end

  def format_overwrite_diff(guild_id, {old_overwrite, nil}) do
    "removed overwrite for #{format_overwrite_target(guild_id, old_overwrite)}"
  end

  # We may get an overwrite sent when nothing actually updated here.
  # To ensure that there's anything worthy of logging, check that
  # the old overwrite and new overwrite are actually not identical.
  def format_overwrite_diff(guild_id, {old_overwrite, new_overwrite})
      when old_overwrite != new_overwrite do
    # Find which explicit allow overwrites were added and removed.
    old_allowed = Permission.from_bitset(old_overwrite.allow)
    new_allowed = Permission.from_bitset(new_overwrite.allow)

    allowed_diff = List.myers_difference(old_allowed, new_allowed)
    added_allowed = allowed_diff |> Keyword.get_values(:ins) |> List.flatten()
    removed_allowed = allowed_diff |> Keyword.get_values(:del) |> List.flatten()

    # Find which explicit deny overwrites were added and removed.
    old_denied = Permission.from_bitset(old_overwrite.deny)
    new_denied = Permission.from_bitset(new_overwrite.deny)

    denied_diff = List.myers_difference(old_denied, new_denied)
    added_denied = denied_diff |> Keyword.get_values(:ins) |> List.flatten()
    removed_denied = denied_diff |> Keyword.get_values(:del) |> List.flatten()

    # Finally, find which overwrites between `removed_denied` <-> `added_allowed`
    # and `removed_allowed` <-> `added_denied` overlap and remove the respective
    # permissions from `removed_allowed` and `removed_denied`.
    # This prevents the following from displaying:
    # - "no longer denied to {x}, now allowed to {x}"
    # - "no longer allowed to {x}, now denied to {x}"
    removed_denied = Enum.reject(removed_denied, &(&1 in added_allowed))
    removed_allowed = Enum.reject(removed_allowed, &(&1 in added_denied))

    "updated overwrite for #{format_overwrite_target(guild_id, new_overwrite)}: " <>
      Enum.join(
        Enum.map(added_allowed, &"now allowed to `#{&1}`") ++
          Enum.map(removed_allowed, &"no longer explicitly allowed to `#{&1}`") ++
          Enum.map(added_denied, &"now denied to `#{&1}`") ++
          Enum.map(removed_denied, &"no longer explicitly denied to `#{&1}`"),
        ", "
      )
  end

  def format_overwrite_diff(_guild_id, {_old_overwrite, _new_overwrite}) do
    ""
  end

  @spec format_overwrite_target(Guild.id(), Overwrite.t()) :: String.t()
  def format_overwrite_target(guild_id, overwrite) do
    if overwrite.type == 0 do
      "role #{Humanizer.human_role(guild_id, overwrite.id)}"
    else
      "user #{Humanizer.human_user(overwrite.id)}"
    end
  end

  @spec format_overwrite(Guild.id(), Overwrite.t(), String.t()) :: String.t()
  def format_overwrite(guild_id, overwrite, what) do
    "#{what} for #{format_overwrite_target(guild_id, overwrite)}:" <>
      (overwrite.allow
       |> Permission.from_bitset()
       |> Enum.map_join(", ", &"can #{&1}")) <>
      (overwrite.deny
       |> Permission.from_bitset()
       |> Enum.map_join(", ", &"can not #{&1}"))
  end
end
