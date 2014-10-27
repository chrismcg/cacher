defmodule SimpleCache do
  use Application

  @wait_for_resources 2500

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    if Application.get_env(:simple_cache, :ensure_contact) do
      :ok = ensure_contact
      ResourceDiscovery.add_local_resource(:simple_cache, node)
      ResourceDiscovery.add_target_resource_type(:simple_cache)
      ResourceDiscovery.trade_resources
      :timer.sleep @wait_for_resources
    end
    SimpleCache.Store.init
    SimpleCache.Supervisor.start_link
  end

  def insert(key, value) do
    case SimpleCache.Store.lookup(key) do
      { :ok, pid } ->
        SimpleCache.Element.replace(pid, value)
        { :ok, [key, value] }
      { :error, _ } ->
        { :ok, pid } = SimpleCache.Element.create(value)
        SimpleCache.Store.insert(key, pid)
        SimpleCache.Event.create(key, value)
        { :ok, [key, value] }
    end
  end

  def lookup(key) do
    try do
      { :ok, pid } = SimpleCache.Store.lookup(key)
      { :ok, value } = SimpleCache.Element.fetch(pid)
      { :ok, value }
    rescue
      _e in MatchError -> { :error, :not_found }
    end
  end

  def delete(key) do
    case SimpleCache.Store.lookup(key) do
      { :ok, pid } ->
        SimpleCache.Element.delete(pid)
        { :ok, key }
      { :error, _reason } -> { :ok, key }
    end
  end

  defp ensure_contact do
    default_nodes = [:"a@gairmi.local", :"b@gairmi.local"]
    case Application.get_env(:simple_cache, :contact_nodes, default_nodes) do
      [] -> { :error, :no_contact_nodes }
      contact_nodes -> ensure_contact(contact_nodes)
    end
  end

  defp ensure_contact(contact_nodes) do
    answering = for n <- contact_nodes, Node.ping(n) == :pong, do: n
    case answering do
      [] -> { :error, :no_contact_nodes_reachable }
      _ ->
        default_time = 2000
        wait_time = Application.get_env(:simple_cache, :wait_time, default_time)
        wait_for_nodes(length(answering), wait_time)
    end
  end

  defp wait_for_nodes(min_nodes, wait_time) do
    slices = 10
    slice_time = Kernel.round(wait_time / slices)
    wait_for_nodes(min_nodes, slice_time, slices)
  end

  defp wait_for_nodes(_min_nodes, _slice_time, 0), do: :ok
  defp wait_for_nodes(min_nodes, slice_time, iterations) do
    if length(Node.list) > min_nodes do
      :ok
    else
      :timer.sleep(slice_time)
      wait_for_nodes(min_nodes, slice_time, iterations - 1)
    end
  end
end
