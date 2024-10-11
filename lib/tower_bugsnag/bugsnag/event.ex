defmodule TowerBugsnag.Bugsnag.Event do
  def from_tower_event(%Tower.Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        plug_conn: plug_conn,
        metadata: metadata
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
      user: user_data(metadata),
      request: request_data(plug_conn),
      metaData: metadata
    }
  end

  def from_tower_event(%Tower.Event{
        kind: :throw,
        reason: value,
        stacktrace: stacktrace,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    %{
      exceptions: [
        %{
          errorClass: "(throw) #{value}",
          message: value,
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app_data(),
      user: user_data(metadata),
      request: request_data(plug_conn),
      metaData: metadata
    }
  end

  def from_tower_event(%Tower.Event{
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    %{
      exceptions: [
        %{
          errorClass: "(exit) #{reason}",
          message: reason,
          stacktrace: stacktrace_entries(stacktrace)
        }
      ],
      app: app_data(),
      user: user_data(metadata),
      request: request_data(plug_conn),
      metaData: metadata
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
      releaseStage: release_stage()
    }
  end

  defp release_stage do
    Application.fetch_env!(:tower_bugsnag, :release_stage)
  end

  if Code.ensure_loaded?(Plug.Conn) do
    @reported_request_headers ["user-agent"]

    defp request_data(%Plug.Conn{} = conn) do
      %{
        httpMethod: conn.method,
        url: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
        headers: request_headers(conn)
      }
    end

    defp request_data(_), do: %{}

    defp request_headers(%Plug.Conn{} = conn) do
      conn.req_headers
      |> Enum.filter(fn {header_name, _header_value} ->
        String.downcase(header_name) in @reported_request_headers
      end)
      |> Enum.into(%{})
    end
  else
    defp request_data(_), do: %{}
  end

  defp user_data(%{user_id: user_id}) do
    %{user: %{id: user_id}}
  end

  defp user_data(_) do
    %{}
  end
end
