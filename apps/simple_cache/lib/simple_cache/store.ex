defmodule SimpleCache.Store do
  alias SimpleCache.Database.KeyToPid

  def init do
    Amnesia.start
    SimpleCache.Database.create ram: [node]
    SimpleCache.Database.wait
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
    Enum.member?(Node.list, node) and (:rpc.call(node(pid), Process, :alive?, [pid]) === true)
  end
end
