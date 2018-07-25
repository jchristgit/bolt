defmodule Bolt.USW.Filter do
  @moduledoc "Defines the base callback that all filters should implement."

  alias Nostrum.Struct.{Message, Snowflake}

  @callback apply(
              Message.t(),
              limit :: non_neg_integer(),
              interval :: non_neg_integer(),
              interval_seconds_ago_snowflake :: Snowflake.t()
            ) :: :action | :passthrough
end
