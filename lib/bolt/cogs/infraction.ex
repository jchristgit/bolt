defmodule Bolt.Cogs.Infraction do
  alias Bolt.Cogs.Infraction.Detail
  alias Bolt.Cogs.Infraction.List
  alias Bolt.Cogs.Infraction.Reason
  alias Bolt.Cogs.Infraction.User
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Paginator
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
      title: "Cannot show infraction detail",
      description: "An infraction ID to look up is required, e.g. `infr detail 3`.",
      color: Constants.color_red()
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, ["reason", maybe_id | reason_list]) do
    response =
      case Integer.parse(maybe_id) do
        {value, _} when value > 0 ->
          case Enum.join(reason_list, " ") do
            "" ->
              %Embed{
                title: "Command error: `infraction reason`",
                description: "The new reason may not be empty.",
                color: Constants.color_red()
              }

            reason ->
              Reason.get_response(msg, value, reason)
          end

        {_value, _} ->
          %Embed{
            title: "Command error: `infraction reason`",
            description: "The infraction ID to update may not be negative.",
            color: Constants.color_red()
          }

        :error ->
          %Embed{
            title: "Command error: `infraction reason`",
            description: "Could not parse an infraction ID from `#{maybe_id}`",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, ["reason"]) do
    response = %Embed{
      title: "Cannot update infraction reason",
      description: "An infraction ID to update is required, e.g. `infr reason 3 spamming`.",
      color: Constants.color_red()
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, ["list" | maybe_type]) do
    {base_embed, pages} = List.prepare_for_paginator(msg, maybe_type)
    Paginator.paginate_over(msg, base_embed, pages)
  end

  def command(msg, ["user" | maybe_user]) do
    case Helpers.into_id(msg.guild_id, Enum.join(maybe_user, " ")) do
      {:ok, snowflake, user} ->
        {base_embed, pages} = User.prepare_for_paginator(msg, {snowflake, user})
        Paginator.paginate_over(msg, base_embed, pages)

      {:error, reason} ->
        response = %Embed{
          title: "invalid command invocation",
          description: "error while parsing arguments: #{reason}",
          color: Constants.color_red()
        }

        {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
    end
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
