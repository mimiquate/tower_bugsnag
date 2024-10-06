defmodule TowerBugsnag.Reporter do
  def report_event(%Tower.Event{} = tower_event) do
    if enabled?() do
      tower_event
      |> TowerBugsnag.Bugsnag.Event.from_tower_event()
      |> TowerBugsnag.Bugsnag.Client.send()
    else
      IO.puts("TowerBugsnag NOT enabled, ignoring...")
    end
  end

  defp enabled? do
    !!Application.fetch_env!(:tower_bugsnag, :api_key)
  end
end
