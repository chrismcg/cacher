defmodule TcpInterfaceTest do
  use ExUnit.Case

  @default_ip 'localhost'
  @default_port 1155

  setup do
    { :ok, socket } = :gen_tcp.connect @default_ip, @default_port, [active: false]
    Application.put_env :simple_cache, :ensure_contact, false
    { :ok, _ } = Application.ensure_all_started :simple_cache
    on_exit fn ->
      :gen_tcp.close(socket)
      Application.stop :simple_cache
    end
    { :ok, socket: socket }
  end

  @tag :integration
  test "inserts a value into the cache", context do
    socket = context[:socket]
    :ok = :gen_tcp.send(socket, 'insert[:test, {"test", "data", 123}]\r\n')
    { :ok, data } = :gen_tcp.recv(socket, 0)
    assert data == 'OK:[:test, {"test", "data", 123}]\r\n'
  end
end
