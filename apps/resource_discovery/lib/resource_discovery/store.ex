defmodule ResourceDiscovery.Store do
  use GenServer

  defmodule State do
    defstruct target_resource_types: [], local_resource_tuples: %{}, found_resource_tuples: %{}
  end

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init([]) do
    { :ok, %State{} }
  end

  def handle_call({:fetch_resources, type}, _from, state) do
    { :reply, Map.fetch(state.found_resource_tuples, type), state }
  end

  def handle_cast({:add_target_resource_type, type}, state) do
    target_types = state.target_resource_types
    new_target_types = [type | List.delete(target_types, type)]
    { :noreply, %{state | target_resource_types: new_target_types } }
  end

  def handle_cast({:add_local_resource, {type, instance}}, state) do
    resource_tuples = state.local_resource_tuples
    new_resource_tuples = add_resource(type, instance, resource_tuples)
    { :noreply, %{state | local_resource_tuples: new_resource_tuples } }
  end

  def handle_cast(:trade_resources, state) do
    resource_tuples = state.local_resource_tuples
    nodes = [Node.self | Node.list]
    Enum.each nodes, fn node ->
      GenServer.cast {__MODULE__, node}, { :trade_resources, {Node.self, resource_tuples} }
    end
    { :noreply, state }
  end

  def handle_cast({:trade_resources, {reply_to, remotes}},
     %State{
       local_resource_tuples: locals,
       target_resource_types: target_types,
       found_resource_tuples: old_found
     } = state) do

    filtered_remotes = resources_for_type(target_types, remotes)
    new_found = add_resources(filtered_remotes, old_found)
    case ReplyTo do
      :noreply -> :ok
      _ -> GenServer.cast({__MODULE__, reply_to}, { :trade_resources, {:noreply, locals}})
    end
    { :noreply, %{state | found_resource_tuples: new_found} }
  end

  defp add_resources([{type, resource} | rest], resource_tuples) do
    add_resources(rest, add_resource(type, resource, resource_tuples))
  end
  defp add_resources([], resource_tuples), do: resource_tuples

  defp add_resource(type, resource, resource_tuples) do
    case Map.fetch(resource_tuples, type) do
      { :ok, resource_list } ->
        new_list = [resource | List.delete(resource_list, resource)]
        Map.put(resource_tuples, type, new_list)
      :error ->
        Map.put(resource_tuples, type, [resource])
    end
  end

  defp resources_for_type(types, resource_tuples) do
    List.foldl types, [], fn(type, acc) ->
      case Map.fetch(resource_tuples, type) do
        {:ok, list} -> (for instance <- list, do: {type, instance}) ++ acc
        :error -> acc
      end
    end
  end
end
