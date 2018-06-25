defmodule Bolt.Cogs.Infraction do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.Paginator
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["detail", maybe_id]) do
    alias Bolt.Cogs.Infraction.Detail

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

  def command(msg, ["expiry", maybe_id, new_expiry]) do
    alias Bolt.Cogs.Infraction.Expiry

    response = Expiry.command(msg, maybe_id, new_expiry)
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["expiry"]) do
    response = "🚫 `expiry` subcommand expects the infraction ID and the new expiry as arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["reason", maybe_id | reason_list]) do
    alias Bolt.Cogs.Infraction.Reason

    response =
      case Integer.parse(maybe_id) do
        {value, _} ->
          case Enum.join(reason_list, " ") do
            "" ->
              "🚫 new infraction reason must not be empty"

            reason ->
              Reason.get_response(msg, value, reason)
          end

        :error ->
          "🚫 invalid argument, expected `int`"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["reason"]) do
    response = "🚫 expected at least 2 arguments, got 0"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["list" | maybe_type]) do
    alias Bolt.Cogs.Infraction.List

    {base_embed, pages} = List.prepare_for_paginator(msg, maybe_type)
    Paginator.paginate_over(msg, base_embed, pages)
  end

  def command(msg, ["user" | maybe_user]) do
    alias Bolt.Cogs.Infraction.User

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
