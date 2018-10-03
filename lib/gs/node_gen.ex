defmodule GS.NodeGen do
  @moduledoc false



  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    ###Logger.debug("Inside init " <> inspect(__MODULE__) <> " with options: " <> inspect(opts))
    [head | tail] = opts
    x = head
    [head | tail] = tail
    algorithm = head

    node_info =
      case algorithm do
        "gossip" ->
          %GS.NodeInfo{
            node_id: x,
            termination_timestamp: 0,
            node_state: %{
              count: 0
            },
            node_pid: self
          }
        "push_sum" ->
          %GS.NodeInfo{
            node_id: x,
            termination_timestamp: 0,
            node_state: %{
              s: x + 1,
              w: 1,
              count: 0
            },
            node_pid: self
          }
      end
    Registry.register(GS.Registry.NodeInfo, self, node_info)
    Registry.register(GS.Registry.NodeIdToPid, x, self)
    {:ok, node_info}
  end

  def handle_call(:get, _from, state) do

    state = get_state(self())
    ##Logger.debug(inspect(__MODULE__) <> " :get " <> inspect(state))

    {:reply, state, state}
  end

  def get_state(node_pid) do
    [{_, this_node_info}] = Registry.lookup(GS.Registry.NodeInfo, node_pid)
    this_node_info
  end

  def update_state(node_pid, node_info) do
    Registry.unregister GS.Registry.NodeInfo, node_pid
    {:ok, _} = Registry.register(GS.Registry.NodeInfo, node_pid, node_info)
  end

  def handle_call({:update, node_info}, _from, state) do
    ##Logger.debug(inspect(__MODULE__) <> " before update: " <> inspect(state))
    update_state(self(), node_info)
    ##Logger.debug(inspect(__MODULE__) <> " after update: " <> inspect(node_info))
    {:reply, :ok, node_info}
  end

  def handle_cast({:process, msg, master_pid, algorithm}, state) do
    #Inform master about activity of node messaging
    #Logger.debug "Before beacon"
    :ok = GenServer.call(GS.Beacon, :beacon)
    #Logger.debug "After beacon"
    #####Logger.debug("Received msg: " <> msg <> " for " <> inspect(agent_id) <> " with master : "<> inspect(master_pid) <> " from : "<> inspect(_from) <> " to: " <> inspect(self()))
    #Logger.debug("Received msg: " <> inspect(msg) <> " for " <> inspect(self()) <> " with master : " <> inspect(master_pid) <> " to: " <> inspect(self()) <> " with state: " <> inspect(state))

    [{_, this_node_info}] = Registry.lookup(GS.Registry.NodeInfo, self)
    Logger.debug("Info for this node" <> inspect(this_node_info))

    [{_, neighbors}] = Registry.lookup(Registry.NeighReg, this_node_info.node_id)
    #####Logger.debug("Neighbors for this node" <> inspect(neighbors))

    #####Logger.debug("chosen_neighbor_node  " <> inspect(chosen_neighbor_node_info))

    [should_terminate, msg] =
      case algorithm do
        "gossip" ->
          #####Logger.debug("In gossip")
          this_node_state = this_node_info.node_state

          ##Logger.debug(inspect(__MODULE__) <> "This node state" <> inspect(this_node_state))
          count = Map.get(this_node_state, :count)
          ##Logger.debug("Count:" <> inspect(count))

          if count == 10 do
            #Logger.debug("Count equals 10 for #{inspect this_node_info.node_pid}. Returning #{inspect count}")
            [true, %{}]
          else
            ####Logger.debug("Buzz Count ne 10. Returning" <> inspect(count))
            count = count + 1
            updated_map = Map.put(this_node_state, :count, count)
            update_state(this_node_info.node_pid, %{this_node_info | node_state: updated_map})
            #Logger.debug("This node info" <> inspect(%{this_node_info | node_state: updated_map}) <> " it's pid: "<> inspect self)

            #TODO Has todo remove
            this_node_info = get_state self
            #Logger.debug("This node state after update" <> inspect(this_node_info))

            [false, %{}]
          end


        "push_sum" ->
          ####Logger.debug("In push sum")
          this_node_info = get_state self
          this_node_state = this_node_info.node_state
          ####Logger.debug("This node state" <> inspect(this_node_state))

          s = Map.get(this_node_state, :s)
          w = Map.get(this_node_state, :w)

          msg_s = Map.get(msg, :s)
          msg_w = Map.get(msg, :w)

          new_s = s + msg_s
          new_w = w + msg_w

          old_sum_est = s / w
          new_sum_est = new_s / new_w
          ####Logger.debug("new s,w : " <> inspect(new_s) <> " "<>inspect(new_w) )

          diff = abs(old_sum_est - new_sum_est)
          ####Logger.debug("Diff : " <> inspect(diff))

          count =
            if diff < :math.pow(10, -10) do
              ####Logger.debug("Diff lesser than threshold: " <> inspect(diff))
              Map.get(this_node_state, :count) + 1
            else
              0
            end

          if count == 3 do
            ####Logger.debug("Count reached 3 for: " <> inspect(this_node_info))
            [true, %{s: new_s / 2, w: new_w / 2}]
          else
            ####Logger.debug("To be updated vals: c: "<> inspect(count) <> "s: " <>inspect(new_s / 2)<> " w: " <>inspect(new_w / 2))
            updated_map = Map.put(this_node_state, :count, count)
            ####Logger.debug(" updated map c"<> inspect(updated_map))
            updated_map = Map.put(updated_map, :s, new_s / 2)
            ####Logger.debug(" updated map s"<> inspect(updated_map))
            updated_map = Map.put(updated_map, :w, new_w / 2)
            ####Logger.debug(" updated map w"<> inspect(updated_map))
            x = get_state self
            GenServer.call(this_node_info.node_pid, {:update, %{x | node_state: updated_map}})
            #TODO Has todo remove
            this_node_info = get_state self
            this_node_state = this_node_info.node_state
            ####Logger.debug("Updated node state" <> inspect(this_node_state))

            [false, %{s: new_s / 2, w: new_w / 2}]
          end
      end

    try do
      chosen_neighbor_node_info = Enum.map(
                                    neighbors,
                                    fn x ->
                                      [{_, nodePid}] = Registry.lookup(GS.Registry.NodeIdToPid, x)
                                      [{_, chosen_neighbor_node_info}] = Registry.lookup(GS.Registry.NodeInfo, nodePid)
                                      #####Logger.debug("Is Process: "<> inspect(chosen_neighbor_node_info.node_pid) <> "  alive: " <> inspect(Process.alive?(chosen_neighbor_node_info.node_pid)))
                                      chosen_neighbor_node_info
                                    end
                                  )
                                  |> Enum.filter(fn x -> Process.alive?(x.node_pid) end)
                                  |> Enum.random()
      Logger.debug("Next chosen neighbor for #{inspect this_node_info.node_id} is #{inspect chosen_neighbor_node_info.node_id}")
      GenServer.cast(chosen_neighbor_node_info.node_pid, {:process, msg, master_pid, algorithm})

    rescue
      Enum.EmptyError ->
        Logger.debug("No alive neighbor found for #{inspect this_node_info.node_id}")
      MatchError ->
        Logger.debug("No entries found in registry #{inspect MatchError} for node#{inspect this_node_info.node_id}")
    end
    if should_terminate do
      Logger.debug("Terminating node id - #{inspect this_node_info.node_id}  pid - #{inspect(this_node_info.node_pid)} at #{:os.system_time(:millisecond)}}")
      Logger.debug "Last beacon captured #{inspect Registry.lookup(GS.Registry.Beacon, :c)}"
      {:stop, :normal, state}
      #{:noreply, state}
      #GenServer.call(GS.Master, {:stop,this_node_info.node_pid})
    else
      {:noreply, state}
    end

  end


end

