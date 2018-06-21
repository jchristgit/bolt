defmodule Bolt.Commander.Checks do
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Nostrum.Struct.Embed
  use Bitwise

  @doc """
  A function that checks whether
  the given message was sent on a
  Gulid. Note that messages retrieved
  via REST do not have the `guild_id`
  attribute set, and thus, will not
  be detected as guild messages properly.
  """
  @spec guild_only(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  def guild_only(msg) do
    case msg.guild_id do
      nil ->
        {:error,
         %Embed{
           title: "A required predicate for this command failed",
           description: "This command can only be used on guilds.",
           color: Constants.color_red()
         }}

      _guild_id ->
        {:ok, msg}
    end
  end

  @spec is_admin?(Integer) :: boolean
  defp is_admin?(permissions) do
    (permissions &&& 0x8) == 0x8
  end

  # Checks if the author of `message` has the permissions specified in `to_check`
  # If yes, returns `{:ok, msg}`
  # If no, returns `{:error, embed}`
  # If an error occured, returns `{:error, embed}`
  @spec has_permission?(Nostrum.Struct.Message.t(), Integer, Embed.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  defp has_permission?(msg, to_check, unauthorized_embed) do
    case Helpers.top_role_for(msg.guild_id, msg.author.id) do
      {:ok, role} ->
        case is_admin?(role.permissions) or (role.permissions &&& to_check) == to_check do
          true -> {:ok, msg}
          false -> {:error, unauthorized_embed}
        end

      {:error, reason} ->
        {:error,
         %Embed{
           title: "Failed to check a required predicate",
           description: "Cannot obtain permission information: #{reason}",
           color: Constants.color_red()
         }}
    end
  end

  @not_allowed_titles [
    "Nah",
    "Nope",
    "I think not...",
    "Let this be lesson for you",
    "Go ahead and cry, baby",
    "The burning you feel? It is shame"
  ]

  @spec missing_permissions_embed(String.t()) :: Embed.t()
  defp missing_permissions_embed(content) do
    %Embed{
      title: Enum.random(@not_allowed_titles),
      description: "You're not allowed to do that - required permission: #{content}",
      color: Constants.color_red()
    }
  end

  @bitflags_manage_roles 0x10000000
  @doc "Checks that the message author has the `MANAGE_ROLES` permission."
  @spec can_manage_roles?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  def can_manage_roles?(msg) do
    has_permission?(msg, @bitflags_manage_roles, missing_permissions_embed("manage roles"))
  end

  @bitflags_manage_messages 0x00002000
  @doc "Checks that the message author has the `MANAGE_MESSSAGES` permission."
  @spec can_manage_messages?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  def can_manage_messages?(msg) do
    has_permission?(msg, @bitflags_manage_messages, missing_permissions_embed("manage messages"))
  end

  @bitflags_kick_members 0x00000002
  @doc "Checks that the message author has the `KICK_MEMBERS` permission."
  @spec can_kick_members?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  def can_kick_members?(msg) do
    has_permission?(msg, @bitflags_kick_members, missing_permissions_embed("kick members"))
  end

  @bitflags_ban_members 0x00000004
  @doc "Checks that the message author has the `BAN_MEMBERS` permission."
  @spec can_ban_members?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, Embed.t()}
  def can_ban_members?(msg) do
    has_permission?(msg, @bitflags_ban_members, missing_permissions_embed("ban members"))
  end
end
