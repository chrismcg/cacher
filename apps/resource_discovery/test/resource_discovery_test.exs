defmodule ResourceDiscoveryTest do
  use ExUnit.Case
  require Logger

  defmodule TestEventHandler do
    use GenEvent

    def add_handler(parent), do: ResourceDiscovery.Event.add_handler(__MODULE__, [parent])
    def remove_handler, do: ResourceDiscovery.Event.remove_handler(__MODULE__, [])

    def handle_event(:resources_traded, [parent] = state) do
      Logger.debug "sending resources traded"
      send parent, :resources_traded
      { :ok, state }
    end
  end

  setup do
    TestEventHandler.add_handler(self)
    on_exit fn ->
      TestEventHandler.remove_handler
    end
  end

  test "can add a local resource" do
    assert :ok = ResourceDiscovery.add_target_resource_type(:test)
    assert :ok = ResourceDiscovery.add_local_resource(:test, self)
    assert :ok = ResourceDiscovery.trade_resources
    assert_receive :resources_traded
    assert { :ok, [self] } == ResourceDiscovery.fetch_resources(:test)
  end
end
