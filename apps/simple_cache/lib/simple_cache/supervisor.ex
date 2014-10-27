defmodule SimpleCache.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, []
  end

  def init([]) do
    children = [
      supervisor(SimpleCache.ElementSupervisor, [], shutdown: 2000),
      worker(SimpleCache.Event, [], shutdown: 2000)
    ]

    opts = [
      strategy: :one_for_one,
      max_restarts: 4,
      max_time: 3600
    ]

    supervise(children, opts)
  end
end
