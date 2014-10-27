defmodule SimpleCache.Store do
  alias SimpleCache.Database.KeyToPid

  def init do
    Amnesia.stop
    Amnesia.Schema.destroy [node]
    Amnesia.start
    if Application.get_env(:simple_cache, :ensure_contact) do
      { :ok, cache_nodes } = ResourceDiscovery.fetch_resources(:simple_cache)
      dynamic_db_init(List.delete(cache_nodes, node))
    else
      dynamic_db_init([])
    end
    :ok
  end

  def insert(key, pid) do
    %KeyToPid{key: key, pid: pid}
    |> KeyToPid.write!
  end

  def lookup(key) do
    case KeyToPid.read!(key) do
      %KeyToPid{key: _key, pid: pid} ->
        if pid_alive?(pid) do
          { :ok, pid }
        else
          { :error, :not_found }
        end

      _ -> { :error, :not_found }
    end
  end

  def delete(pid) do
    case KeyToPid.read_at! pid, :pid do
      [%KeyToPid{} = record] -> KeyToPid.delete!(record)
      _ -> :ok
    end
  end

  defp pid_alive?(pid) when node(pid) === node, do: Process.alive?(pid)
  defp pid_alive?(pid) do
    Enum.member?(Node.list, node(pid)) and (:rpc.call(node(pid), Process, :alive?, [pid]) === true)
  end

  defp dynamic_db_init([]) do
    SimpleCache.Database.create ram: [node]
    SimpleCache.Database.wait
  end

  defp dynamic_db_init(cache_nodes) do
    add_extra_nodes(cache_nodes)
  end

  @wait_for_tables 5000

  defp add_extra_nodes([new_node | tail]) do
    case :mnesia.change_config(:extra_db_nodes, [new_node]) do
      { :ok, [new_node] } ->
        Amnesia.Table.add_copy(:schema, node(), :memory)
        Amnesia.Table.add_copy(SimpleCache.Database, node(), :memory)
        Amnesia.Table.add_copy(KeyToPid, node(), :memory)
        Amnesia.Table.wait(:mnesia.system_info(:tables), @wait_for_tables)
      _ -> add_extra_nodes(tail)
    end
  end
  defp add_extra_nodes([]), do: nil
end
