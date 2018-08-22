defmodule Bolt.USW.Rule do
  @moduledoc "Defines the base callback that all rules should implement."

  alias Nostrum.Struct.{Message, Snowflake}

  @callback apply(
              Message.t(),
              limit :: non_neg_integer(),
              interval :: non_neg_integer(),
              interval_seconds_ago_snowflake :: Snowflake.t()
            ) :: :action | :passthrough
end
