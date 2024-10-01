defmodule TowerBugsnag do
  @moduledoc """
  Documentation for `TowerBugsnag`.
  """

  @behaviour Tower.Reporter

  @impl true
  def report_event(event) do
    TowerBugsnag.Reporter.report_event(event)
  end
end
