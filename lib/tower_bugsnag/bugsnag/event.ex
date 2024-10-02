defmodule TowerBugsnag.Bugsnag.Event do
  def from_tower_event(%Tower.Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        plug_conn: plug_conn
      }) do
    %{
      exceptions: [
        %{
          errorClass: inspect(exception.__struct__),
          message: Exception.message(exception),
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app_data(),
      request: request_data(plug_conn)
    }
  end

  def from_tower_event(%Tower.Event{
        kind: :throw,
        reason: value,
        stacktrace: stacktrace,
        plug_conn: plug_conn
      }) do
    %{
      exceptions: [
        %{
          errorClass: "(throw)",
          message: value,
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app_data(),
      request: request_data(plug_conn)
    }
  end

  def from_tower_event(%Tower.Event{
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        plug_conn: plug_conn
      }) do
    %{
      exceptions: [
        %{
          errorClass: "(exit)",
          message: reason,
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app_data(),
      request: request_data(plug_conn)
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

  defp app_data do
    %{
      releaseStage: environment()
    }
  end

  defp environment do
    Application.fetch_env!(:tower_bugsnag, :environment)
  end

  if Code.ensure_loaded?(Plug.Conn) do
    defp request_data(%Plug.Conn{} = conn) do
      %{
        httpMethod: conn.method,
        url: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}"
      }
    end

    defp request_data(_), do: %{}
  else
    defp request_data(_), do: %{}
  end
end
