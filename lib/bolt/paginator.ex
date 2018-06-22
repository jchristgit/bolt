defmodule Bolt.Paginator do
  use GenServer
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Message

  ## Client API

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec paginate_over(Message.t(), Embed.t(), [Embed.t()]) :: no_return()
  def paginate_over(original_msg, base_page, []) do
    base_page = Map.put(base_page, :description, "Seems like there's nothing here yet.")
    {:ok, _msg} = Api.create_message(original_msg.channel_id, embed: base_page)
  end

  def paginate_over(original_msg, base_page, [page]) do
    {:ok, _msg} =
      Api.create_message(original_msg.channel_id, embed: Map.merge(base_page, page, fn _k, v1, v2 -> if v2 != nil, do: v2, else: v1 end))
  end

  def paginate_over(original_msg, base_page, pages) do
    initial_embed =
      Map.merge(
        base_page,
        %{Enum.fetch!(pages, 0) | footer: %Footer{text: "Page 1 / #{length(pages)}"}},
        fn _k, v1, v2 -> if v2 != nil, do: v2, else: v1 end
      )

    {:ok, msg} = Api.create_message(original_msg.channel_id, embed: initial_embed)

    # Add the navigator reactions to the embed. Sleep shortly to respect ratelimits.
    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "⬅")
    Process.sleep(250)
    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "➡")
    Process.sleep(250)
    {:ok} = Api.create_reaction(original_msg.channel_id, msg.id, "❌")

    paginator_map = %{
      message: msg,
      current_page: 0,
      base_page: base_page,
      pages: pages
    }

    GenServer.cast(__MODULE__, {:add, paginator_map})

    # Drop the paginator from the pool after 15 minutes.
    Process.send_after(__MODULE__, {:drop, msg.id}, 15 * 60 * 1_000)
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
      if paginator.message.author.id == reaction.user_id do
        {:noreply, paginators}
      else
        case reaction.emoji.name do
          "⬅" ->
            Api.delete_user_reaction(
              paginator.message.channel_id,
              paginator.message.id,
              reaction.emoji.name,
              reaction.user_id
            )

            # Are we at the first page? If so, ignore the reaction.
            if paginator.current_page == 0 do
              {:noreply, paginators}
            else
              {_, paginator} =
                Map.get_and_update(paginator, :current_page, fn page -> {page, page - 1} end)

              new_page =
                Map.merge(
                  paginator.base_page,
                  Enum.fetch!(paginator.pages, paginator.current_page),
                  fn _k, v1, v2 -> if v2 != nil, do: v2, else: v1 end
                )

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

            # Are we at the last page? If so, ignore the reaction.
            if paginator.current_page == length(paginator.pages) - 1 do
              {:noreply, paginators}
            else
              {_, paginator} =
                Map.get_and_update(paginator, :current_page, fn page -> {page, page + 1} end)

              new_page =
                Map.merge(
                  paginator.base_page,
                  Enum.fetch!(paginator.pages, paginator.current_page),
                  fn _k, v1, v2 -> if v2 != nil, do: v2, else: v1 end
                )

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
      end
    else
      _error -> {:noreply, paginators}
    end
  end

  @impl true
  def handle_info({:drop, msg_id}, paginators) do
    {:noreply, Map.delete(paginators, msg_id)}
  end
end
