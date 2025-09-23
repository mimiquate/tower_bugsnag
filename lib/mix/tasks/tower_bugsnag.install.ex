defmodule Mix.Tasks.TowerBugsnag.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Installs TowerBugsnag"
  end

  @spec example() :: String.t()
  def example do
    "mix tower_bugsnag.install"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```sh
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) and
     Code.ensure_loaded?(Tower.Igniter) and
     function_exported?(Tower.Igniter, :runtime_configure_reporter, 3) do
  defmodule Mix.Tasks.TowerBugsnag.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl true
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{group: :tower, example: __MODULE__.Docs.example()}
    end

    @impl true
    def igniter(igniter) do
      igniter
      |> Tower.Igniter.reporters_list_append(TowerBugsnag)
      |> Tower.Igniter.runtime_configure_reporter(
        :tower_bugsnag,
        api_key: code_value(~s[System.get_env("BUGSNAG_API_KEY")]),
        release_stage: code_value(~s[System.get_env("DEPLOYMENT_ENV", to_string(config_env()))])
      )
    end

    defp code_value(value) do
      {:code, Sourceror.parse_string!(value)}
    end
  end
else
  defmodule Mix.Tasks.TowerBugsnag.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    @error_message """
    The task 'tower_bugsnag.install' requires igniter and tower >= 0.8.4. Please install igniter or update tower and try again.

    For more information, see: https://hexdocs.pm/igniter/readme.html#installation
    """
    use Mix.Task

    @impl true
    def run(_argv) do
      Mix.shell().error(@error_message)
      exit({:shutdown, 1})
    end
  end
end
