defmodule SimpleCache.ElementSupervisor do
  use Supervisor

  @server __MODULE__

  def start_link do
    Supervisor.start_link __MODULE__, [], name: @server
  end

  def start_child(value, lease_time) do
    Supervisor.start_child @server, [value, lease_time]
  end

  def init([]) do
    children = [
      worker(SimpleCache.Element, [], restart: :temporary, shutdown: :brutal_kill)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [
      strategy: :simple_one_for_one,
      max_restarts: 0,
      max_seconds: 1
    ]
    supervise(children, opts)
  end
end
