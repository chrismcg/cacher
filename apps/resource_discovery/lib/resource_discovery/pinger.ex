defmodule ResourceDiscovery.Pinger do
  use GenServer

  @timeout 5 * 1000

  def start_link do
    GenServer.start_link __MODULE__, [], []
  end

  def init([]) do
    { :ok, current_node_set, @timeout }
  end

  def handle_info(:timeout, state) do
    ping(state)
    { :noreply, state, @timeout }
  end

  defp ping(state) do
    node_list = Set.union(state, current_node_set)
    Enum.each node_list, &Node.ping/1
    ResourceDiscovery.trade_resources
  end

  defp current_node_set do
    Enum.into(Node.list, HashSet.new)
  end
end
