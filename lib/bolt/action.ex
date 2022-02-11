defmodule Bolt.Action do
  alias Ecto.Changeset

  @callback changeset(map(), map()) :: Changeset.t()

  @callback run(any(), map()) :: any()
end
