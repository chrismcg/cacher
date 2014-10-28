defmodule HttpInterface do
  use Application
  require Logger

  @default_port 1156

  def start(_type, _args) do
    Logger.debug "HttpInterface start"
    port = Application.get_env(:http_interface, :port, @default_port)
    HttpInterface.Server.start_link(port)
  end
end
