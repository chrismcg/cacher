defmodule TcpInterface.Supervisor do
  use Supervisor

  def start_link(listen_socket) do
    Supervisor.start_link(__MODULE__, [listen_socket], name: __MODULE__)
  end

  def start_child, do: Supervisor.start_child(__MODULE__, [])

  def init(listen_socket) do
    children = [
      worker(TcpInterface.Server, [listen_socket], restart: :temporary, shutdown: :brutal_kill)
    ]

    opts = [
      strategy: :simple_one_for_one,
      max_retries: 0,
      max_seconds: 1
    ]

    supervise(children, opts)
  end
end
