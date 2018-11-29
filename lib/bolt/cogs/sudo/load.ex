defmodule Bolt.Cogs.Sudo.Load do
  @moduledoc "Load a command or alias."

  alias Bolt.Commander.Server
  alias Nostrum.Api
  alias Nostrum.Struct.User
  require Logger

  defp to_command_module(name) do
    String.to_existing_atom("Elixir.Bolt.Cogs." <> name)
  rescue
    _ -> nil
  end

  def command(msg, [name, "aliased", "to", alias_target]) when name == alias_target do
    reply = "🚫 cannot create an alias that references itself"
    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end

  def command(msg, [name, "aliased", "to", alias_target]) do
    reply =
      case :ets.lookup(:commands, alias_target) do
        [{_name, {:alias, _target}}] ->
          "🚫 cannot create an alias to an alias"

        [_result] ->
          case :ets.lookup(:commands, name) do
            [] ->
              Server.add_alias(name, alias_target)

              Logger.info(
                "`#{User.full_name(msg.author)}` aliased command `#{name}` to `#{alias_target}`."
              )

              "👌 `#{name}` is now aliased to `#{alias_target}`"

            [{_name, {:alias, target}}] ->
              "🚫 `#{name}` is already aliased to `#{target}`"

            [{_name, command_group}] when is_map(command_group) ->
              "🚫 `#{name}` is already loaded as a command group"

            [{_name, command_module}] ->
              short_modname = String.replace_leading("#{command_module}", "Elixir.", "")
              "🚫 `#{name}` is already loaded as `#{short_modname}`"
          end

        [] ->
          "🚫 `#{alias_target}` is an unknown command or command group"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end

  def command(msg, [name, module_name]) do
    reply =
      case to_command_module(module_name) do
        nil ->
          "🚫 unknown command module `#{module_name}`"

        module ->
          case :ets.lookup(:commands, name) do
            [{name, {:alias, target}}] ->
              "🚫 `#{name}` is already loaded as an alias to `#{target}`"

            [{name, subcommands}] when is_map(subcommands) ->
              "🚫 `#{name}` is already loaded as a command group"

            [{name, module}] ->
              short_modname = String.replace_leading("#{module}", "Elixir.", "")
              "🚫 `#{name}` is already loaded as `#{short_modname}`"

            [] ->
              Server.add_command(name, module)

              Logger.info(
                "`#{User.full_name(msg.author)}` loaded command `#{name}` as `#{module}`."
              )

              "👌 `#{module_name}` is now loaded as `#{name}`"
          end
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end

  def command(msg, _args) do
    reply = """
    ℹ usage:
    - `sudo load <command_name:str> <module:str>`
    - `sudo load <name:str> aliased to <target_command:str>`
    """

    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end
end
