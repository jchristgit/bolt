defmodule Bolt.Action do
  @moduledoc "Base behaviour for any actions."
  alias Ecto.Changeset

  @callback changeset(map(), map()) :: Changeset.t()

  @callback run(any(), map()) :: any()
end
