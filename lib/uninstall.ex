defmodule Mix.Tasks.Uninstall do
  use Mix.Task
  use SimpleCache.Database

  @shortdoc "Uninstall the mnesia database"

  def run(_) do
    Amnesia.start

    SimpleCache.Database.destroy

    Amnesia.stop

    Amnesia.Schema.destroy
  end
end
