defmodule TcpInterface do
  use Application

  @default_port 1155

  def start(_start_type, _start_args) do
    port = Application.get_env(:tcp_interface, :port, @default_port)
    { :ok, listen_socket } = :gen_tcp.listen(port, active: true)
    case TcpInterface.Supervisor.start_link(listen_socket) do
      {:ok, pid} ->
        TcpInterface.Supervisor.start_child
        {:ok, pid}
      other -> { :error, other }
    end
  end
end
