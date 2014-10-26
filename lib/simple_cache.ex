defmodule SimpleCache do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    SimpleCache.Store.init
    SimpleCache.Supervisor.start_link
  end

  def insert(key, value) do
    case SimpleCache.Store.lookup(key) do
      { :ok, pid } -> SimpleCache.Element.replace(pid, value)
      { :error, _ } ->
        { :ok, pid } = SimpleCache.Element.create(value)
        SimpleCache.Store.insert(key, pid)
        SimpleCache.Event.create(key, value)
    end
  end

  def lookup(key) do
    try do
      { :ok, pid } = SimpleCache.Store.lookup(key)
      { :ok, value } = SimpleCache.Element.fetch(pid)
      { :ok, value }
    rescue
      _e -> { :error, :not_found }
    end
  end

  def delete(key) do
    case SimpleCache.Store.lookup(key) do
      { :ok, pid } -> SimpleCache.Element.delete(pid)
      { :error, _reason } -> :ok
    end
  end
end
