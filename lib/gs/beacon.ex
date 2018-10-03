defmodule GS.Beacon do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_opts) do
    #Registry.start_link(keys: :duplicate, name: GS.Registry.Beacon)
    Registry.register(GS.Registry.Beacon, :c, :os.system_time(:millisecond))
    Logger.debug("#{inspect __MODULE__} get beacon ts #{inspect(Registry.lookup(GS.Registry.Beacon, :c))}")
    {:ok, %{}}
  end


  def handle_call(:beacon, _from, state) do
    #Logger.debug("received beacon message #{inspect(:os.system_time(:millisecond))}")
    :ok = Registry.unregister GS.Registry.Beacon, :c
    #Logger.debug("#{inspect __MODULE__} get beacon ts #{inspect(Registry.lookup(GS.Registry.Beacon, :c))}")
    {:ok, _} = Registry.register GS.Registry.Beacon, :c, :os.system_time(:millisecond)
    {:reply, :ok, state}
  end

  def handle_call(:get, _from, state) do
    Logger.debug("#{inspect __MODULE__} get beacon ts #{inspect(Registry.lookup(GS.Registry.Beacon, :c))}")
    [{self, timestamp}] = Registry.lookup(GS.Registry.Beacon, :c)
    {:reply, timestamp, state}
  end

  def handle_cast(:beacon, state) do
    Logger.debug("received beacon message #{inspect(:os.system_time(:millisecond))}")
    Registry.unregister GS.Registry.Beacon, :c
    Logger.debug("#{inspect __MODULE__} get beacon ts #{inspect(Registry.lookup(GS.Registry.Beacon, :c))}")
    {:ok, _} = Registry.register GS.Registry.Beacon, :c, :os.system_time(:millisecond)
    {:noreply, state}
  end

end