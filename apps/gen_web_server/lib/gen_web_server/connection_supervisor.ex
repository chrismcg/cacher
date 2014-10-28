defmodule GenWebServer.ConnectionSupervisor do
  use Supervisor
  require Logger

  def start_link(callback, ip, port, user_args) do
    Logger.debug "GenWebServer.ConnectionSupervisor start_link"
    { :ok, pid } = Supervisor.start_link(__MODULE__, [callback, ip, port, user_args])
    start_child(pid)
    { :ok, pid }
  end

  def start_child(server) do
    Logger.debug "GenWebServer.ConnectionSupervisor start_child"
    Supervisor.start_child(server, [])
  end

  def init([callback, ip, port, user_args]) do
    Logger.debug "GenWebServer.ConnectionSupervisor init"
    socket_opts = [
      :binary,
      active: false,
      packet: :http_bin,
      reuseaddr: true
    ]
    if ip != :undefined do
      socket_opts = [{:ip, ip} | socket_opts]
    end

    Logger.debug "GenWebServer.ConnectionSupervisor init: listening"
    { :ok, listen_socket } = :gen_tcp.listen(port, socket_opts)

    children = [
      worker(
        GenWebServer.Server,
        [callback, listen_socket, user_args],
        restart: :temporary,
        shutdown: :brutal_kill
      )
    ]

    opts = [
      strategy: :simple_one_for_one,
      max_restarts: 1000,
      max_timeout: 3600
    ]

    Logger.debug "GenWebServer.ConnectionSupervisor init: supervising"
    supervise children, opts
  end
end
