defmodule TowerBugsnag.Bugsnag.Event do
  @default_app_type "elixir"

  def from_tower_event(
        %Tower.Event{kind: :error, reason: exception, stacktrace: stacktrace} = tower_event
      ) do
    exception_event(
      inspect(exception.__struct__),
      Exception.message(exception),
      stacktrace,
      event_context(tower_event)
    )
  end

  def from_tower_event(
        %Tower.Event{kind: :throw, reason: value, stacktrace: stacktrace} = tower_event
      ) do
    formatted_value = inspect(value)

    exception_event(
      "(throw) #{formatted_value}",
      formatted_value,
      stacktrace,
      event_context(tower_event)
    )
  end

  def from_tower_event(
        %Tower.Event{kind: :exit, reason: reason, stacktrace: stacktrace} = tower_event
      ) do
    formatted_reason = Exception.format_exit(reason)

    exception_event(
      "(exit) #{formatted_reason}",
      formatted_reason,
      stacktrace,
      event_context(tower_event)
    )
  end

  def from_tower_event(
        %Tower.Event{level: level, kind: :message, reason: message, stacktrace: stacktrace} =
          tower_event
      ) do
    exception_event(
      inspect(message),
      inspect(message),
      stacktrace,
      event_context(
        tower_event,
        severity: severity_from_tower_level(level)
      )
    )
  end

  defp exception_event(class, message, stacktrace, context) do
    context
    |> Map.put(
      :exceptions,
      [
        %{
          errorClass: class,
          message: message,
          stacktrace: stacktrace_entries(stacktrace)
        }
      ]
    )
  end

  defp event_context(
         %Tower.Event{plug_conn: plug_conn, metadata: metadata} = tower_event,
         extra \\ %{}
       ) do
    %{
      unhandled: !manual_report?(tower_event),
      app: app_data(),
      device: device_data(),
      user: user_data(metadata),
      request: request_data(plug_conn),
      metaData: json_prepare(metadata)
    }
    |> Map.merge(Enum.into(extra, %{}))
  end

  defp stacktrace_entries(nil) do
    []
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

  defp severity_from_tower_level(level) when level in [:warning, :info] do
    level
  end

  defp severity_from_tower_level(_) do
    :error
  end

  defp app_data do
    %{
      releaseStage: release_stage(),
      type: @default_app_type,
      version: app_version()
    }
  end

  defp device_data do
    {:ok, hostname} = :inet.gethostname()

    %{
      hostname: to_string(hostname),
      osName: os_name(),
      osVersion: os_version()
    }
  end

  defp app_version do
    Application.fetch_env!(:tower_bugsnag, :app_version)
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

  defp manual_report?(%{by: nil}), do: true
  defp manual_report?(_), do: false

  defp os_version do
    case :os.version() do
      {major, minor, patch} -> "#{major}.#{minor}.#{patch}"
      version -> inspect(version)
    end
  end

  defp os_name do
    case :os.type() do
      {family, name} -> "#{family}:#{name}"
      type -> inspect(type)
    end
  end

  defp json_prepare(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      {json_prepare(k), json_prepare(v)}
    end)
    |> Enum.into(%{})
  end

  defp json_prepare(list) when is_list(list) do
    list
    |> Enum.map(fn element ->
      json_prepare(element)
    end)
  end

  defp json_prepare(value)
       when is_tuple(value) or
              is_pid(value) or
              is_reference(value) or
              is_port(value) or
              is_function(value) do
    inspect(value)
  end

  defp json_prepare(value), do: value
end
