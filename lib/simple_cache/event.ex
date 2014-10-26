defmodule SimpleCache.Event do
  def start_link, do: GenEvent.start_link(__MODULE__)

  def add_handler(handler, args) do
    GenEvent.add_handler(__MODULE__, handler, args)
  end

  def delete_handler(handler, args) do
    GenEvent.delete_handler(__MODULE__, handler, args)
  end

  def lookup(key) do
    GenEvent.notify(__MODULE__, {:lookup, key})
  end

  def create(key, value) do
    GenEvent.notify(__MODULE__, {:create, {key, value}})
  end

  def replace(key, value) do
    GenEvent.notify(__MODULE__, {:replace, {key, value}})
  end

  def delete(key) do
    GenEvent.notify(__MODULE__, {:delete, key})
  end
end
