defmodule Bolt.Cogs.Paginate do
  alias Bolt.Paginator
  alias Nostrum.Struct.Embed

  def command(msg, _args) do
    base_page = %Embed{
      title: "Paginator command"
    }

    pages = [
      %Embed{
        description: "page one"
      },
      %Embed{
        description: "page two"
      },
      %Embed{
        description: "page three"
      },
      %Embed{
        description: "page four"
      },
      %Embed{
        description: "page five"
      }
    ]

    Paginator.paginate_over(msg, base_page, pages)
  end
end
