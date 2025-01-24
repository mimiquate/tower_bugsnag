defmodule TowerBugsnag.Reporter do
  alias TowerBugsnag.Bugsnag

  def report_event(%Tower.Event{} = tower_event) do
    if enabled?() do
      event = Bugsnag.Event.from_tower_event(tower_event)
      async(fn -> Bugsnag.Client.send(event) end)
    else
      IO.puts("TowerBugsnag NOT enabled, ignoring...")
    end
  end

  defp enabled? do
    !!Application.fetch_env!(:tower_bugsnag, :api_key)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
