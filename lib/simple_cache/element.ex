defmodule SimpleCache.Element do
  use GenServer

  @server __MODULE__
  @default_lease_time 60 * 60 * 24 # 1 day

  defmodule State do
    defstruct value: nil, lease_time: nil, start_time: nil
  end

  ## API

  def start_link(value, lease_time) do
    GenServer.start_link @server, [value, lease_time], []
  end

  def create(value, lease_time) do
    SimpleCache.Supervisor.start_child(value, lease_time)
  end
  def create(value), do: create(value, @default_lease_time)

  def fetch(pid), do: GenServer.call(pid, :fetch)

  def replace(pid, value), do: GenServer.cast(pid, { :replace, value })

  def delete(pid), do: GenServer.cast(pid, :delete)

  ## Callbacks

  def init([value, lease_time]) do
    now = :calendar.local_time
    start_time = :calendar.datetime_to_gregorian_seconds(now)
    { :ok,
      %State{value: value, lease_time: lease_time, start_time: start_time},
      time_left(start_time, lease_time)
    }
  end

  def time_left(_start_time, :infinity), do: :infinity
  def time_left(start_time, lease_time) do
    now = :calendar.local_time
    current_time = :calendar.datetime_to_gregorian_seconds(now)
    time_elapsed = current_time - start_time
    time_remaining = lease_time - time_elapsed
    cond do
      time_remaining <= 0 -> 0
      true -> time_remaining * 1000
    end
  end

  def handle_call(:fetch, _from, %State{value: value, start_time: start_time, lease_time: lease_time} = state) do
    { :reply, { :ok, value }, state, time_left(start_time, lease_time) }
  end

  def handle_cast({:replace, value}, %State{start_time: start_time, lease_time: lease_time} = state) do
    { :noreply, %{state | value: value}, time_left(start_time, lease_time) }
  end

  def handle_cast(:delete, state), do: { :stop, :normal, state }

  def handle_info(:timeout, state), do: { :stop, :normal, state }

  def terminate(_reason, _state) do
    SimpleCache.Store.delete(self)
    :ok
  end

  def code_change(_old_version, state, _extra), do: { :ok, state }

end
