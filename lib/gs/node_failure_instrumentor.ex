defmodule GS.Node_failure_instrumentor do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(msg, state) do
    master_pid = Map.get(msg, :master_pid)
    total_nodes = Map.get(msg, :total_nodes)
    num_kill_nodes = Map.get(msg, :num_nodes)
    type =
      case Map.get(msg, :type) do
        ":normal" ->
          :normal

        ":kill" ->
          :kill
      end


    if num_kill_nodes > 0 do
      :rand.seed(:exsplus, {101, 102, 103})
      total_node_ids = Enum.map(0..total_nodes - 1, fn x -> x end)
      for x <- 1..num_kill_nodes do
        rand_pos = Enum.random(1..length(total_node_ids)-1)
        {node_id, total_node_ids} = List.pop_at(total_node_ids, rand_pos)
        #Logger.debug("Kill node id - #{inspect node_id} at #{inspect total_node_ids} at pos #{rand_pos}")
        [{_, node_pid}] = Registry.lookup(GS.Registry.NodeIdToPid, node_id)
        #Logger.debug("Kill node id - #{inspect node_id} pid - #{inspect node_pid}")
        Process.exit(node_pid, type)

      end

    end

    {:noreply, state}
  end
end
