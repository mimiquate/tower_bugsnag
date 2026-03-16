defmodule TowerBugsnag.Reporter do
  require Logger

  alias TowerBugsnag.Bugsnag

  def report_event(%Tower.Event{} = tower_event) do
    if enabled?() do
      event = Bugsnag.Event.from_tower_event(tower_event)

      async(fn ->
        Bugsnag.Client.send(event)
        |> case do
          {:error, reason} ->
            log_report_error(reason)

          {:ok, {status_code, _headers, body}} when status_code in 400..599 ->
            log_report_error(body)

          _ ->
            nil
        end
      end)
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

  defp log_report_error(reason) do
    Logger.error("[TowerBugsnag] Error reporting event to BugSnag: #{inspect(reason)}")
  end
end
