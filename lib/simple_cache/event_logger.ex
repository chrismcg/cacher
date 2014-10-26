defmodule SimpleCache.EventLogger do
  use GenEvent
  require Logger

  def add_handler, do: SimpleCache.Event.add_handler(__MODULE__, [])

  def delete_handler, do: SimpleCache.Event.delete_handler(__MODULE__, [])

  def handle_event({:create, {key, value}}, state) do
    Logger.info("create(#{key}, #{value})")
    {:ok, state}
  end

  def handle_event({:lookup, key}, state) do
    Logger.info("lookup(#{key})")
    {:ok, state}
  end

  def handle_event({:delete, key}, state) do
    Logger.info("delete(#{key})")
    {:ok, state}
  end

  def handle_event({:replace, {key, value}}, state) do
    Logger.info("replace(#{key}, #{value})")
    {:ok, state}
  end
end
