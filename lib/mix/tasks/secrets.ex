defmodule Mix.Tasks.Secrets do
  use Mix.Task
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    Secrets.main(args)
  end
end
