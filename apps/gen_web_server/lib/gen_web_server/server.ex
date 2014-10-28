defmodule GenWebServer.Server do
  use GenServer
  require Logger

  defmodule State do
    defstruct listen_socket: nil,
              socket: nil,
              request_line: nil,
              headers: [],
              body: "",
              content_remaining: 0,
              callback: nil,
              user_data: nil,
              parent: nil
  end

  def start_link(callback, listen_socket, user_args) do
    Logger.debug "GenWebServer.Server start_link"
    GenServer.start_link(__MODULE__, [callback, listen_socket, user_args, self], [])
  end

  def init([callback, listen_socket, user_args, parent]) do
    Logger.debug "GenWebServer.Server init"
    { :ok, user_data } = callback.init(user_args)
    state = %State{
      listen_socket: listen_socket,
      callback: callback,
      user_data: user_data,
      parent: parent
    }

    { :ok, state, 0 }
  end

  def handle_call(_request, _from, state) do
    { :reply, :ok, state }
  end

  def handle_cast(_request, state) do
    { :noreply, state }
  end

  def handle_info({:http, _sock, {:http_request, _, _, _} = request}, state) do
    Logger.debug "HI: :http_request"
    :inet.setopts(state.socket, [{:active, :once}])
    { :noreply, %{state | request_line: request} }
  end

  def handle_info({:http, _sock, {:http_header, _, name, _, value}}, state) do
    Logger.debug "HI: :http_header"
    :inet.setopts(state.socket, [{:active, :once}])
    { :noreply, header(name, value, state) }
  end

  def handle_info({:http, _sock, :http_eoh}, %State{content_remaining: content_remaining} = state) when content_remaining == 0 do
    Logger.debug "HI: :http_eoh 0 content remaining"
    { :stop, :normal, handle_http_request(state) }
  end

  def handle_info({:http, _sock, :http_eoh}, state) do
    Logger.debug "HI: :http_eoh"
    :inet.setopts(state.socket, [{:active, :once}, {:packet, :raw}])
    { :noreply, state }
  end

  def handle_info({:tcp, _sock, data}, state) when is_binary(data) do
    Logger.debug "HI: :tcp"
    content_remaining = state.content_remaining - byte_size(data)
    body = state.body <> data
    new_state = %{state | body: body, content_remaining: content_remaining}
    if content_remaining > 0 do
      :inet.setopts(state.socket, [{:active, :once}])
      { :noreply, new_state }
    else
      { :stop, :normal, handle_http_request(new_state) }
    end
  end

  def handle_info({:tcp_closed, _sock}, state) do
    Logger.debug "HI: :tcp_closed"
    { :stop, :normal, state }
  end

  def handle_info(:timeout, %State{listen_socket: listen_socket, parent: parent} = state) do
    Logger.debug "HI: :timeout"
    { :ok, socket } = :gen_tcp.accept(listen_socket)
    GenWebServer.ConnectionSupervisor.start_child(parent)
    :inet.setopts(socket, [{:active, :once}])
    { :noreply, %{state | socket: socket }}
  end

  defp header(:"Content-Length" = name, value, state) do
    Logger.debug "HI: Content-Length header: #{value}"
    content_length = String.to_integer(value)
    %{state | content_remaining: content_length, headers: [{name, value} | state.headers]}
  end

  defp header("Expect" = name, "100-continue" = value, state) do
    Logger.debug "HI: Expect header"
    :gen_tcp.send(state.socket, GenWebServer.http_reply(100))
    %{state | headers: [{name, value} | state.headers]}
  end

  defp header(name, value, state) do
    Logger.debug "HI: header #{inspect name}"
    %{state | headers: [{name, value} | state.headers]}
  end

  defp handle_http_request(%State{callback: callback,
                                  request_line: request_line,
                                  headers: headers,
                                  body: body,
                                  user_data: user_data} = state) do
    {:http_request, method, _, _ } = request_line
    Logger.debug "HI: handle_http_request #{method} #{inspect request_line}"
    reply = dispatch(method, request_line, headers, body, callback, user_data)
    :gen_tcp.send(state.socket, reply)
    state
  end

  defp dispatch(:GET, request, headers, _body, callback, user_data) do
    callback.get(request, headers, user_data)
  end

  defp dispatch(:DELETE, request, headers, _body, callback, user_data) do
    callback.delete(request, headers, user_data)
  end

  defp dispatch(:HEAD, request, headers, _body, callback, user_data) do
    callback.head(request, headers, user_data)
  end

  defp dispatch(:POST, request, headers, body, callback, user_data) do
    callback.post(request, headers, body, user_data)
  end

  defp dispatch(:PUT, request, headers, body, callback, user_data) do
    callback.put(request, headers, body, user_data)
  end

  defp dispatch(:TRACE, request, headers, body, callback, user_data) do
    callback.trace(request, headers, body, user_data)
  end

  defp dispatch(:OPTIONS, request, headers, body, callback, user_data) do
    callback.options(request, headers, body, user_data)
  end

  defp dispatch(_other, request, headers, body, callback, user_data) do
    callback.other_methods(request, headers, body, user_data)
  end
end
