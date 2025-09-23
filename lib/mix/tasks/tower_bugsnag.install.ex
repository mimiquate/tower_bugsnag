if Code.ensure_loaded?(Igniter) and
     Code.ensure_loaded?(Tower.Igniter) and
     function_exported?(Tower.Igniter, :runtime_configure_reporter, 3) do
  defmodule Mix.Tasks.TowerBugsnag.Install do
    @example "mix igniter.install tower_bugsnag"

    @shortdoc "Installs TowerBugsnag. Invoke with `mix igniter.install tower_bugsnag`"
    @moduledoc """
    #{@shortdoc}

    ## Example

    ```bash
    #{@example}
    ```
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{group: :tower, example: @example}
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Tower.Igniter.reporters_list_append(TowerBugsnag)
      |> Tower.Igniter.runtime_configure_reporter(
        :tower_bugsnag,
        api_key: {:code, Sourceror.parse_string!(~s[System.get_env("BUGSNAG_API_KEY")])}
      )
    end
  end
else
  defmodule Mix.Tasks.TowerBugsnag.Install do
    @example "mix igniter.install tower_bugsnag"

    @shortdoc "Installs TowerBugsnag. Invoke with `mix igniter.install tower_bugsnag`"

    @moduledoc """
    #{@shortdoc}

    ## Example

    ```bash
    #{@example}
    ```
    """

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'tower_bugsnag.install' requires igniter and tower >= 0.8.4. Please install igniter or update tower and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
