defmodule Bolt.Cogs.USW.Unset do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.USWFilterConfig
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
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
