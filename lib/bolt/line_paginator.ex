defmodule Bolt.LinePaginator do
  use GenServer
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Message

  ## Client API

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec paginate_over(Message.t(), [Embed.t()]) :: no_return()
  def paginate_over(original_msg, pages) when length(pages) == 1 do
    {:ok, _msg} = Api.create_message(original_msg.channel_id, Enum.fetch!(pages, 0))
  end

  def paginate_over(original_msg, pages) do
    initial_embed = %{Enum.fetch!(pages, 0) | footer: %Footer{text: "Page 1 / #{length(pages)}"}}
    {:ok, msg} = Api.create_message(original_msg.channel_id, embed: initial_embed)

    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "⬅")
    Process.sleep(250)
    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "➡")
    Process.sleep(250)
    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "❌")
    Process.sleep(50)

    paginator_map = %{
      message: msg,
      current_page: 0,
      pages: pages
    }

    GenServer.cast(__MODULE__, {:add, paginator_map})
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add, paginator_map}, paginators) do
    {:noreply, Map.put(paginators, paginator_map.message.id, paginator_map)}
  end

  # Handle the MESSAGE_REACTION_ADD event
  @impl true
  def handle_cast({:MESSAGE_REACTION_ADD, reaction}, paginators) do
    with {:ok, paginator} <- Map.fetch(paginators, reaction.message_id) do
      case reaction.emoji.name do
        "⬅" ->
          Api.delete_user_reaction(
            paginator.message.channel_id,
            paginator.message.id,
            reaction.emoji.name,
            reaction.user_id
          )

          if paginator.current_page == 0 do
            {:noreply, paginators}
          else
            {_, paginator} =
              Map.get_and_update(paginator, :current_page, fn page -> {page, page - 1} end)

            new_page = Enum.fetch!(paginator.pages, paginator.current_page)

            new_page =
              Map.put(new_page, :footer, %Footer{
                text: "Page #{paginator.current_page + 1} / #{length(paginator.pages)}"
              })

            {:ok, _msg} = Api.edit_message(paginator.message, embed: new_page)
            {:noreply, %{paginators | reaction.message_id => paginator}}
          end

        "➡" ->
          Api.delete_user_reaction(
            paginator.message.channel_id,
            paginator.message.id,
            reaction.emoji.name,
            reaction.user_id
          )

          if paginator.current_page == length(paginator.pages) - 1 do
            {:noreply, paginators}
          else
            {_, paginator} =
              Map.get_and_update(paginator, :current_page, fn page -> {page, page + 1} end)

            new_page = Enum.fetch!(paginator.pages, paginator.current_page)

            new_page =
              Map.put(new_page, :footer, %Footer{
                text: "Page #{paginator.current_page + 1} / #{length(paginator.pages)}"
              })

            {:ok, _msg} = Api.edit_message(paginator.message, embed: new_page)
            {:noreply, %{paginators | reaction.message_id => paginator}}
          end

        "❌" ->
          Api.delete_message(paginator.message)
          {:noreply, Map.delete(paginators, paginator.message.id)}

        _any_reaction ->
          {:noreply, paginators}
      end
    else
      _error -> {:noreply, paginators}
    end
  end
end
