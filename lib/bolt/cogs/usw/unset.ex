defmodule Bolt.Cogs.USW.Unset do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Schema.USWRuleConfig
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["usw unset <rule:str>"]

  @impl true
  def description,
    do: """
    Unsets configuration for the given rule, effectively disabling it.

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, [rule]) do
    rule = String.upcase(rule)

    response =
      if rule in USWRuleConfig.existing_rules() do
        case Repo.get_by(USWRuleConfig, guild_id: msg.guild_id, rule: rule) do
          nil ->
            "🚫 there is no configuration set up for rule `#{rule}`"

          object ->
            {:ok, _struct} = Repo.delete(object)

            ModLog.emit(
              msg.guild_id,
              "CONFIG_UPDATE",
              "#{User.full_name(msg.author)} (`#{msg.author.id}`) deleted USW " <>
                "configuration for rule `#{rule}`"
            )

            "👌 deleted configuration for rule `#{rule}`"
        end
      else
        "🚫 unknown rule: `#{Helpers.clean_content(rule)}`"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
