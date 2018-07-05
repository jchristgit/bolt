defmodule Bolt.Cogs.USW.Unset do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Helpers, Repo}
  alias Bolt.Schema.USWFilterConfig
  alias Nostrum.Api

  @impl true
  def usage, do: ["usw unset <filter:str>"]

  @impl true
  def description,
    do: """
    Unsets configuration for the given filter, effectively disabling it.

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, [filter]) do
    filter = String.upcase(filter)

    response =
      if filter not in USWFilterConfig.existing_filters() do
        "🚫 unknown filter: `#{Helpers.clean_content(filter)}`"
      else
        case Repo.get_by(USWFilterConfig, guild_id: msg.guild_id, filter: filter) do
          nil ->
            "🚫 there is no configuration set up for filter `#{filter}`"

          object ->
            {:ok, _struct} = Repo.delete(object)
            "👌 deleted configuration for filter `#{filter}`"
        end
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
