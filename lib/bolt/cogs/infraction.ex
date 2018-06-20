defmodule Bolt.Cogs.Infraction do
  alias Bolt.Cogs.Infraction.Detail
  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  def command(msg, ["detail", maybe_id]) do
    response =
      case Integer.parse(maybe_id) do
        {value, _} when value > 0 ->
          Detail.get_response(msg, value)

        {_value, _} ->
          %Embed{
            title: "Command error: `infraction detail`",
            description: "The infraction ID to look up may not be negative.",
            color: Constants.color_red()
          }

        :error ->
          %Embed{
            title: "Command error: `infraction detail`",
            description:
              "`infraction detail` expects the infraction ID " <>
                "as its sole argument, got '#{maybe_id}' instead",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, ["detail"]) do
    response = %Embed{
      title: "`#{msg.content}`",
      description: "An infraction ID to look up is required, e.g. `infr detail 3`.",
      color: Constants.color_red()
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, anything) do
    response = %Embed{
      title: "unknown subcommand or args: #{anything}",
      description: """
      Valid subcommands: `detail`
      Use `help infraction` for more information.
      """,
      color: Constants.color_red()
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
