defmodule SimpleCacheTest do
  use ExUnit.Case

  setup_all do
    SimpleCache.Store.init
    on_exit &Amnesia.stop/0
  end

  setup do
    :mnesia.clear_table SimpleCache.Database.KeyToPid
    :ok
  end

  test "insert works" do
    assert SimpleCache.insert :test, self
  end

  test "lookup works" do
    { :error, :not_found } = SimpleCache.lookup :test
    SimpleCache.insert :test, self
    assert { :ok, self } == SimpleCache.lookup :test
  end

  test "delete works" do
    SimpleCache.insert :test, self
    assert { :ok, self() } == SimpleCache.lookup :test
    SimpleCache.delete :test
    assert { :error, :not_found } == SimpleCache.lookup :test
  end
end
