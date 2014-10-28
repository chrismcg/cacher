defmodule ResourceDiscovery.Event do
  def start_link, do: GenEvent.start_link(name: __MODULE__)

  def add_handler(handler, args) do
    GenEvent.add_handler(__MODULE__, handler, args)
  end

  def remove_handler(handler, args) do
    GenEvent.remove_handler(__MODULE__, handler, args)
  end

  def resources_traded do
    GenEvent.notify(__MODULE__, :resources_traded)
  end
end
