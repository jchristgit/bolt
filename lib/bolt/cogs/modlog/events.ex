defmodule Bolt.Cogs.ModLog.Events do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Paginator
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  def command(msg, []) do
    pages =
      ModLogConfig.valid_events()
      |> Stream.map(&"• #{&1}")
      |> Stream.chunk_every(6)
      |> Enum.map(
        &%Embed{
          description: Enum.join(&1, "\n")
        }
      )

    base_embed = %Embed{
      title: "Known events",
      color: Constants.color_blue()
    }

    Paginator.paginate_over(msg, base_embed, pages)
  end

  def command(msg, _args) do
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
