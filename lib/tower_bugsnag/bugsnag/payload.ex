defmodule TowerBugsnag.Bugsnag.Event do
  def from_tower_event(%Tower.Event{
        kind: :error,
        reason: exception
      }) do
    %{
      exceptions: [
        %{
          errorClass: inspect(exception.__struct__),
          message: Exception.message(exception),
          stacktrace: []
        }
      ]
    }
  end
end
