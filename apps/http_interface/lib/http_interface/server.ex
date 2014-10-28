defmodule HttpInterface.Server do
  @behaviour GenWebServer
  require Logger

  def start_link(port), do: GenWebServer.start_link(__MODULE__, port, [])
  def start_link(ip, port), do: GenWebServer.start_link(__MODULE__, ip, port, [])

  def init([]) do
    { :ok, [] }
  end

  def get({:http_request, :GET, {:abs_path, <<"/", key :: binary>>}, _}, _headers, _user_data) do
    case SimpleCache.lookup(key) do
      { :ok, value } -> GenWebServer.http_reply(200, [], value)
      { :error, :not_found } -> GenWebServer.http_reply(404, "Sorry, no such key")
    end
  end

  def delete({:http_request, :DELETE, {:abs_path, <<"/", key :: binary>>}, _}, _headers, _user_data) do
    SimpleCache.delete(key)
    GenWebServer.http_reply(200)
  end

  def put({:http_request, :PUT, {:abs_path, <<"/", key :: binary>>}, _}, _headers, body, _user_data) do
    Logger.debug "HttpInterface.Server put #{key} -> #{body}"
    SimpleCache.insert(key, body)
    GenWebServer.http_reply(200)
  end

  def post(_request, _headers, _body, _user_data), do: GenWebServer.http_reply(501)
  def head(_request, _headers, _user_data), do: GenWebServer.http_reply(501)
  def options(_request, _headers, _body, _user_data), do: GenWebServer.http_reply(501)
  def trace(_request, _headers, _body, _user_data), do: GenWebServer.http_reply(501)
  def other_methods(_request, _headers, _body, _user_data), do: GenWebServer.http_reply(501)
end
