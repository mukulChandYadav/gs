defmodule GS.Node do

  use Agent

  require Logger

  @moduledoc false

  def start_link(opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " with options: " <> inspect(opts))
    #TODO: Add node info here
    [head|tail] = opts
    agent_id = head
    [head|tail] = tail
    algo = head

    agent_node_info =
      case algo do
        "gossip" ->
          %GS.NodeInfo{node_id: agent_id, termination_timestamp: 0, node_state: %{count: 0}, node_pid: -1}
        "push_sum" ->
          %GS.NodeInfo{node_id: agent_id, termination_timestamp: 0, node_state: %{s: agent_id + 1, w: 1, count: 0}, node_pid: -1}
      end
    Logger.debug("Inside start_link agent node info " <> inspect(agent_node_info) )
    Agent.start_link(fn -> agent_node_info end)
  end

  def send_msg(agent_id, master_pid, algorithm, msg) do

    #Logger.debug("Received msg: " <> msg <> " for " <> inspect(agent_id) <> " with master : "<> inspect(master_pid) <> " from : "<> inspect(_from) <> " to: " <> inspect(self()))
    Logger.debug("Received msg: " <> inspect(msg) <> " for " <> inspect(agent_id) <> " with master : "<> inspect(master_pid) <>" to: " <> inspect(self()))
    [{_, this_node_info}] = Registry.lookup(GS.Registry.NodeInfo, agent_id)
    Logger.debug("Info for this node" <> inspect(this_node_info))

    [{_, neighbors}] = Registry.lookup(Registry.NeighReg, agent_id)
    #Logger.debug("Neighbors for this node" <> inspect(neighbors))

    try do
    chosen_neighbor_node_info = Enum.map(
                             neighbors,
                             fn x ->
                               [{_, chosen_neighbor_node_info}] = Registry.lookup(GS.Registry.NodeInfo, x)
                               #Logger.debug("Is Process: "<> inspect(chosen_neighbor_node_info.node_pid) <> "  alive: " <> inspect(Process.alive?(chosen_neighbor_node_info.node_pid)))
                               chosen_neighbor_node_info
                             end
                           )
                           |> Enum.filter(fn x -> Process.alive?(x.node_pid) end)
                           |> Enum.random()

    #Logger.debug("chosen_neighbor_node  " <> inspect(chosen_neighbor_node_info))

    [should_terminate, msg] =
      case algorithm do
        "gossip" ->
          #Logger.debug("In gossip")
          this_node_info = Agent.get(this_node_info.node_pid, fn x -> x end)
          this_node_state = this_node_info.node_state

          Logger.debug("This node state" <> inspect(this_node_state))
          count = Map.get(this_node_state, :count)
          Logger.debug("Count:" <> inspect(count))

          if count == 10 do
            Logger.debug("Count equals 10. Returning" <> inspect(count))
            [true, %{}]
          else
            Logger.debug("Buzz Count ne 10. Returning" <> inspect(count))
            count = count + 1
            updated_map = Map.put(this_node_state, :count, count)
            Agent.update(this_node_info.node_pid, fn x ->
              %{x | node_state: updated_map}
            end)
            #TODO Has todo remove
            this_node_info = Agent.get(this_node_info.node_pid, fn x -> x end)
            this_node_state = this_node_info.node_state
            Logger.debug("This node state" <> inspect(this_node_state))

            [false, %{}]
          end


        "push_sum" ->
          Logger.debug("In push sum")
          this_node_info = Agent.get(this_node_info.node_pid, fn x -> x end)
          this_node_state = this_node_info.node_state
          Logger.debug("This node state" <> inspect(this_node_state))

          s = Map.get(this_node_state, :s)
          w = Map.get(this_node_state, :w)

          msg_s = Map.get(msg, :s)
          msg_w = Map.get(msg, :w)

          new_s = s + msg_s
          new_w = w + msg_w

          old_sum_est = s/w
          new_sum_est = new_s/new_w

          diff = abs(old_sum_est - new_sum_est)
          Logger.debug("Diff : " <> inspect(diff))

          count  =
            if diff < :math.pow(10, -10) do
              Logger.debug("Diff lesser than threshold: " <> inspect(diff))
              Map.get(this_node_state, :count) + 1
            else
              0
            end

          if count == 3 do
            Logger.debug("Count reached 3 for: " <> inspect(this_node_info))
            [true, %{}]
          else
            updated_map = Map.put(this_node_state, :count, count)
            updated_map = Map.put(this_node_state, :s, new_s/2)
            updated_map = Map.put(this_node_state, :w, new_w/2)
            Agent.update(this_node_info.node_pid, fn x ->
              %{x | node_state: updated_map}
            end)
            #TODO Has todo remove
            this_node_info = Agent.get(this_node_info.node_pid, fn x -> x end)
            this_node_state = this_node_info.node_state
            Logger.debug("Updated node state" <> inspect(this_node_state))

            [false, %{s: new_s/2, w: new_w/2}]
          end
      end

    #Logger.debug(" Chosen neighbor id" <> inspect(chosen_neighbor_node_info.node_id))

    #Logger.debug(" This node " <> inspect(this_node_info.node_id) <> " with count: " <> inspect(this_node_info.node_state) <> " should terminate : " <> inspect(should_terminate))

    if should_terminate do
      Logger.debug("Terminating node id - " <> inspect(agent_id) <> " pid - " <> inspect(this_node_info.node_pid))
      #TODO: Communicate to master about it's exit

      Process.unlink(this_node_info.node_pid)
      Agent.stop(this_node_info.node_pid)
      #Process.exit(
       # this_node_info.node_pid,
        #:normal
      #)
    end

    GS.Node.send_msg(chosen_neighbor_node_info.node_id, master_pid, algorithm, msg)

    rescue
      Enum.EmptyError ->

    end

  end

end
