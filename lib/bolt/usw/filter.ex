defmodule Bolt.USW.Filter do
  @moduledoc "Defines the base callback that all filters should implement."

  @callback apply(Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer()) ::
              :action | :passthrough
end
