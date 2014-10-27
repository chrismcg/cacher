defmodule TcpInterface.Server do
  use GenServer

  def start_link([listen_socket]) do
    GenServer.start_link(__MODULE__, [listen_socket], [])
  end

  def init([listen_socket]) do
    { :ok, %{listen_socket: listen_socket}, 0 }
  end

  def handle_call(message, _from, state) do
    { :reply, { :ok, message }, state }
  end

  def handle_cast(:stop, state) do
    { :stop, :normal, state }
  end

  def handle_info({:tcp, socket, raw_data}, state) do
    new_state = handle_data(socket, raw_data, state)
    { :noreply, new_state }
  end

  def handle_info({:tcp_closed, _socket}, state) do
    { :stop, :normal, state }
  end

  def handle_info(:timeout, %{listen_socket: listen_socket} = state) do
    { :ok, _sock } = :gen_tcp.accept(listen_socket)
    TcpInterface.Supervisor.start_child
    { :noreply, state }
  end

  defp handle_data(socket, raw_data, state) do
    :gen_tcp.send(socket, raw_data)
    state
  end
end
