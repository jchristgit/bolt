defmodule Bolt.Cogs.Paginate do
  alias Bolt.LinePaginator
  alias Nostrum.Struct.Embed

  def command(msg, _args) do
    pages = [
      %Embed{
        title: "page one"
      },
      %Embed{
        title: "page two"
      },
      %Embed{
        title: "page three"
      },
      %Embed{
        title: "page four"
      },
      %Embed{
        title: "page five"
      }
    ]

    LinePaginator.paginate_over(msg, pages)
  end
end
