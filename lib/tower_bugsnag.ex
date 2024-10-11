defmodule TowerBugsnag do
  @moduledoc """
  Documentation for `TowerBugsnag`.
  """

  @behaviour Tower.Reporter

  @impl true
  defdelegate report_event(event), to: TowerBugsnag.Reporter
end
