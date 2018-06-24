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
    case Integer.parse(maybe_id) do
      {value, _} when value > 0 ->
        embed = Detail.get_response(msg, value)
        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      :error ->
        response = "🚫 invalid argument, expected `int`"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, ["detail"]) do
    response = "🚫 `detail` subcommand expects the infraction ID as its sole argument"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["reason", maybe_id | reason_list]) do
    response =
      case Integer.parse(maybe_id) do
        {value, _} ->
          case Enum.join(reason_list, " ") do
            "" ->
              response = "🚫 new infraction reason must not be empty"
              {:ok, _msg} = Api.create_message(msg.channel_id, response)

            reason ->
              embed = Reason.get_response(msg, value, reason)
              {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
          end

        :error ->
          response = "🚫 invalid argument, expected `int`"
          {:ok, _msg} = Api.create_message(msg.channel_id, response)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, ["reason"]) do
    response = "🚫 expected at least 2 arguments, got 0"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
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
        response = "🚫 invalid user or snowflake: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, _anything) do
    response = "🚫 invalid subcommand, view `help infraction` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
