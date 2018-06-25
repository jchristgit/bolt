defmodule Bolt.Cogs.Lsar do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Paginator
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Guild.Role

  @spec command(
          Nostrum.Struct.Message.t(),
          [String.t()]
        ) :: {:ok, Nostrum.Struct.Message.t()} | reference()
  def command(msg, []) do
    case Repo.get(SelfAssignableRoles, msg.guild_id) do
      nil ->
        response = "🚫 this guild has not configured any self-assignable roles"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      role_row ->
        pages =
          role_row.roles
          |> Stream.map(&Integer.to_string/1)
          |> Stream.map(&Converters.to_role(msg.guild_id, &1))
          |> Stream.filter(&match?({:ok, _role}, &1))
          |> Stream.map(fn {:ok, role} -> role end)
          |> Enum.sort_by(& &1.name)
          |> Stream.map(&"• #{&1.name} (#{Role.mention(&1)})")
          |> Stream.chunk_every(10)
          |> Enum.map(&%Embed{description: Enum.join(&1, "\n")})

        base_embed = %Embed{
          title: "Self-assignable roles",
          color: Constants.color_blue(),
          footer: %Footer{
            text: "Use `assign <role>` to assign or `remove <role>` to remove a role."
          }
        }

        Paginator.paginate_over(msg, base_embed, pages)
    end
  end

  def command(msg, _args) do
    response = "🚫 this command accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
