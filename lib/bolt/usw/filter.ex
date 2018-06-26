defmodule Bolt.USW.Filter do
  @callback apply(Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer()) ::
              :action | :passthrough
end
