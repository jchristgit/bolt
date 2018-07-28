defmodule Bolt.Cogs.USW.Status do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Constants, Paginator, Repo}
  alias Bolt.Schema.{USWRuleConfig, USWPunishmentConfig}
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  alias Timex.Duration
  import Ecto.Query, only: [from: 2]
  use Timex

  @impl true
  def usage, do: ["usw status"]

  @impl true
  def description,
    do: """
    Shows the current status of USW.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, []) do
    query = from(config in USWRuleConfig, where: config.guild_id == ^msg.guild_id, select: config)

    pages =
      query
      |> Repo.all()
      |> Enum.sort_by(& &1.rule)
      |> Stream.map(
        &%Field{
          name: "`#{&1.rule}`",
          value: """
          max: #{&1.count}
          per: #{&1.interval}s
          """,
          inline: true
        }
      )
      |> Stream.chunk_every(6)
      |> Enum.map(&%Embed{fields: &1})

    case pages do
      [] ->
        response = "🚫 no rules configured on this guild"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      _ ->
        base_embed = %Embed{
          title: "uncomplicated spam wall: status",
          description: format_punishment_config(msg.guild_id),
          color: Constants.color_blue()
        }

        Paginator.paginate_over(msg, base_embed, pages)
    end
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `usw status`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  defp format_punishment_config(guild_id) do
    case Repo.get(USWPunishmentConfig, guild_id) do
      nil ->
        "no punishment is configured"

      %USWPunishmentConfig{
        duration: duration,
        escalate: escalate,
        punishment: "TEMPROLE",
        data: %{"role_id" => role_id}
      } ->
        duration_string =
          duration
          |> Duration.from_seconds()
          |> Timex.format_duration(:humanized)

        "configured punishment: `TEMPROLE` of role `#{role_id}` for #{duration_string}" <>
          ", automatic punishment escalation is " <> if escalate, do: "enabled", else: "disabled"
    end
  end
end
