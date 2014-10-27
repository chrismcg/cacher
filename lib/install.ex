defmodule Mix.Tasks.Install do
  use Mix.Task
  use SimpleCache.Database

  @shortdoc "Install the mnesia database"

  def run(_) do
    Amnesia.Schema.create

    Amnesia.start

    SimpleCache.Database.create ram: [node]

    SimpleCache.Database.wait

    Amnesia.stop
  end
end
