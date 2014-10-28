defmodule GenWebServer do
  use Behaviour

  defcallback init(args :: List) :: any
  defcallback head(request :: Tuple, headers :: List, user_data :: any) :: String
  defcallback get(request :: Tuple, headers :: List, user_data :: any) :: String
  defcallback delete(request :: Tuple, headers :: List, user_data :: any) :: String
  defcallback options(request :: Tuple, headers :: List, body :: String, user_data :: any) :: String
  defcallback post(request :: Tuple, headers :: List, body :: String, user_data :: any) :: String
  defcallback put(request :: Tuple, headers :: List, body :: String, user_data :: any) :: String
  defcallback trace(request :: Tuple, headers :: List, body :: String, user_data :: any) :: String
  defcallback other_methods(request :: Tuple, headers :: List, body :: String, user_data :: any) :: String

  def start_link(callback, port, user_args) do
    start_link(callback, :undefined, port, user_args)
  end

  def start_link(callback, ip, port, user_args) do
    GenWebServer.ConnectionSupervisor.start_link(callback, ip, port, user_args)
  end

  def http_reply(code, headers, body) do
    length = byte_size(body)
    full_headers = [{"Content-Length", length} | headers]
    head = """
    HTTP/1.1 #{format_response(code)}\r
    #{format_headers(full_headers)}
    """
    head = String.slice head, 0..-2

    if length == 0 do
      head
    else
      "#{head}#{body}"
    end
  end

  def http_reply(code) do
    http_reply(code, "")
  end

  def http_reply(code, body) do
    http_reply(code, [{"Content-Type", "text/html"}], body)
  end

  defp format_headers([{header, text} | rest]) do
    ["#{header}: #{text}\r\n" | format_headers(rest)]
  end

  defp format_headers([]), do: []

  def format_response(100), do: "100 Continue"
  def format_response(200), do: "200 OK"
  def format_response(404), do: "404 NOT FOUND"
  def format_response(501), do: "501 NOT IMPLEMENTED"
  def format_response(code), do: Integer.to_string(code)
end
