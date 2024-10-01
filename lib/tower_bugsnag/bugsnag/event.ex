defmodule TowerBugsnag.Bugsnag.Event do
  def from_tower_event(%Tower.Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace
      }) do
    %{
      exceptions: [
        %{
          errorClass: inspect(exception.__struct__),
          message: Exception.message(exception),
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app()
    }
  end

  defp stacktrace_entries(stacktrace) do
    stacktrace
    |> Enum.map(&stacktrace_entry(&1))
  end

  defp stacktrace_entry({m, f, a, location}) do
    entry = %{
      "method" => entry_method(m, f, a)
    }

    entry =
      if location[:file] do
        Map.put(entry, "file", to_string(location[:file]))
      else
        entry
      end

    if location[:line] do
      Map.put(entry, "lineNumber", location[:line])
    else
      entry
    end
  end

  defp entry_method(m, f, arity) when is_integer(arity) do
    Exception.format_mfa(m, f, arity)
  end

  defp entry_method(m, f, args) when is_list(args) do
    Exception.format_mfa(m, f, length(args))
  end

  defp app do
    %{
      releaseStage: environment()
    }
  end

  defp environment do
    Application.fetch_env!(:tower_bugsnag, :environment)
  end
end
