defmodule GS.Node do

  use Agent

  require Logger

  @moduledoc false

  def start_link(opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " with options: " <> inspect(opts))
    #TODO: Add node info here
    Agent.start_link(fn -> %{} end)
  end

  def send_msg(agent_id, master_pid, _from, algorithm, msg) do

    Logger.debug("Received msg: " <> msg <> " for " <> inspect(agent_id) <> " from master : " <> inspect(self()))

    #TODO: Get neighbors
    #node_ids = Registry.keys(Registry.NeighReg, master_pid)

    [{_, this_node_info}] = Registry.lookup(GS.Registry.NodeInfo, agent_id)
    Logger.debug("Info for this node" <> inspect(this_node_info))

    [{_, neighbors}] = Registry.lookup(Registry.NeighReg, agent_id)
    Logger.debug("Neighbors for this node" <> inspect(neighbors))

    chosen_neighbor_node = Enum.map(
                             neighbors,
                             fn x ->
                               [{_, chosen_neighbor_node_info}] = Registry.lookup(GS.Registry.NodeInfo, x)
                               chosen_neighbor_node_info
                             end
                           )
                           |> Enum.filter(fn x -> Process.alive?(x.node_pid) end)
                           |> Logger.debug()
                           |> Enum.random()


    Logger.debug("chosen_neighbor_node  " <> inspect(chosen_neighbor_node))

    [{_, chosen_neighbor_node_info}] = Registry.lookup(GS.Registry.NodeInfo, chosen_neighbor_node)
    Logger.debug("chosen_neighbor_node_info " <> inspect(chosen_neighbor_node_info))

    should_terminate =
      case algorithm do
        :gossip ->
          Logger.debug("In gossip")
          false

        :push_sum ->
          Logger.debug("In push sum")
          false

        _ ->

          false
      end

    GS.Node.send_msg(chosen_neighbor_node_info.node_pid, master_pid, this_node_info.node_id, algorithm, "abc")

    if should_terminate do
      Logger.debug("Terminating " <> inspect(agent_id))
      Process.exit(
        agent_id,
        :normal
      )
    end
 
  end


  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    #TODO: Get/Update bucket to store generic values based on algorithm type, or more specifically algorithm will provide get/update function
    Logger.debug("Inside " <> inspect(__MODULE__))
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def update(bucket, key, value) do
    Logger.debug("Inside " <> inspect(__MODULE__))
    #TODO: Get/Update bucket to store generic values based on algorithm type, or more specifically algorithm will provide get/update function
    Agent.update(bucket, &Map.put(&1, key, value))
  end

end
