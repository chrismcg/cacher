defmodule TcpInterfaceTest do
  use ExUnit.Case

  @default_ip 'localhost'
  @default_port 1155

  setup do
    { :ok, socket } = :gen_tcp.connect @default_ip, @default_port, [active: false]
    on_exit fn -> :gen_tcp.close(socket) end
    { :ok, socket: socket }
  end

  @tag :integration
  test "sends commands over tcp stream and receives response", context do
    socket = context[:socket]
    :ok = :gen_tcp.send(socket, "Hello\r\n")
    { :ok, data } = :gen_tcp.recv(socket, 0)
    assert data == 'Hello\r\n'
  end
end
