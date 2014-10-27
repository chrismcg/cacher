defmodule ResourceDiscovery do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      worker(ResourceDiscovery.Store, []),
      worker(ResourceDiscovery.Pinger, [])
    ]
    Supervisor.start_link children, strategy: :one_for_one
  end

  def add_target_resource_type(type) do
    GenServer.cast ResourceDiscovery.Store, { :add_target_resource_type, type }
  end

  def add_local_resource(type, instance) do
    GenServer.cast ResourceDiscovery.Store, { :add_local_resource, {type, instance}}
  end

  def fetch_resources(type) do
    GenServer.call ResourceDiscovery.Store, {:fetch_resources, type}
  end

  def trade_resources do
    GenServer.cast ResourceDiscovery.Store, :trade_resources
  end
end
