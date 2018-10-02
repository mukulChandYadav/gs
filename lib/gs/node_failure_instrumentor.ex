defmodule GS.Node_failure_instrumentor do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    Logger.debug("" <> inspect(__MODULE__) <> " Inside start link " )
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(msg, state) do
    node_ids = Registry.keys(Registry.NodeInfo, GS.Master)
    node_pids = Enum.map(node_ids, fn node_id ->
      [{_, this_node_info}] = Registry.lookup(GS.Registry.NodeInfo, node_id)
      Logger.debug("" <> inspect(__MODULE__) <> " Node info: " <> inspect(this_node_info))
    end)


    {:noreply, state}
  end
end