defmodule GS.Master do
  @moduledoc false

  require Logger

  use GenServer

  def start_link(opts) do
    #Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(opts) do

    # Create node registry <node_id, node_info>
    Registry.start_link(keys: :unique, name: GS.Registry.NodeInfo)
    Registry.start_link(keys: :unique, name: GS.Registry.NodeIdToPid)
    {:ok, %{}}
  end


  def handle_call({:process, opts}, _from, state) do
    #Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    commandline_arg = opts

    #Logger.debug("command line_arg" <> inspect(commandline_arg))
    [head | tail] = commandline_arg
    num_nodes = String.to_integer(head)
    [head | tail] = tail
    topology = head
    [head | tail] = tail
    algorithm = head

    Logger.debug "command line_arg nodes - #{inspect num_nodes}  topology -  #{inspect topology} algorithm - #{inspect algorithm} "

    # Populate neighbor registry
    GS.Neighbors.main(topology, num_nodes)
    node_ids = Registry.keys(Registry.NeighReg, self())
    #Logger.debug("Prepared node_ids" <> inspect(node_ids))

    node_info_list = Enum.map(
      node_ids,
      fn x ->
        {:ok, agent_node_pid} = GS.NodeGen.start_link([x, algorithm, topology])
        #Logger.debug("" <> inspect(__MODULE__) <> " node pid " <> inspect(agent_node_pid))
        node_info = GenServer.call(agent_node_pid, :get)
        node_info
      end
    )
    #Logger.debug("node_list" <> inspect(node_info_list))
    master_pid = self()
    # Send message to random node
    random_seed_node = Enum.random(node_info_list)
    #Logger.debug("Calling random node " <> inspect(random_seed_node.node_pid))
    msg =
      case algorithm do
        "gossip" ->
          %{}

        "push_sum" ->
          random_seed_node.node_state
      end

    start_timestamp = :os.system_time(:millisecond)

    '''
      Initiate seed node message
    '''
    GenServer.cast(random_seed_node.node_pid, {:process, msg, master_pid, algorithm})

    wait_for_convergence(start_timestamp)
    end_timestamp = get_beacon_timestamp()

    time_interval = end_timestamp - start_timestamp
    IO.puts("Time taken: #{inspect time_interval}ms")
    {:reply, :ok, state}
  end

  defp wait_for_convergence(last_timestamp) do
    receive do
    after
      5_000 ->
        last_beacon_ts = get_beacon_timestamp()
        Logger.info("Timestamps: last- #{inspect last_timestamp}  beacon- #{inspect last_beacon_ts}")
        if(last_timestamp >= last_beacon_ts) do
          Logger.info("No message passing in a while. Assuming network to be dormant.")
        else
          wait_for_convergence(last_beacon_ts)
        end
    end
  end

  defp get_beacon_timestamp() do
    Logger.debug("#{inspect __MODULE__} get beacon ts #{inspect(Registry.lookup(GS.Registry.Beacon, :c))}" )
    timestamp = GenServer.call(GS.Beacon, :get)
    timestamp
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end



  #  defp wait_for_messages_to_complete(last_timestamp) do
  #
  #    receive do
  #    after
  #      5_000 ->
  #        last_beacon_ts = get_beacon_timestamp()
  #        Logger.info("Timestamps: last- " <> inspect(last_timestamp) <> " beacon-" <> inspect(last_beacon_ts))
  #        if(last_timestamp >= last_beacon_ts) do
  #          Logger.info("No message passing in a while. Assuming network to be dormant.")
  #        else
  #          wait_for_messages_to_complete(last_beacon_ts)
  #        end
  #    end
  #
  #
  #    #    Process.sleep(5000)
  #    #    last_beacon_ts = get_beacon_timestamp()
  #    #    Logger.info("Timestamps: last- " <> inspect(last_timestamp) <> " beacon-" <> inspect(last_beacon_ts))
  #    #    if(last_timestamp >= last_beacon_ts) do
  #    #      Logger.info("No message passing in a while. Assuming network to be dormant.")
  #    #    else
  #    #      wait_for_messages_to_complete(last_beacon_ts)
  #    #    end
  #  end

  #  def handle_call({:stop, node_pid}, _from, state) do
  #    Logger.debug("received beacon message to stop " <> inspect(:os.system_time(:millisecond)))
  #    Process.unlink(node_pid)
  #    if Process.alive? node_pid do
  #      GenServer.stop(node_pid, :normal)
  #    else
  #      Logger.warn("Process id: #{inspect node_pid} already dead")
  #    end
  #
  #    {:reply, :ok, state}
  #  end


  #  def handle_cast({:stop, node_pid}, state) do
  #    #Logger.debug("received beacon message " <> inspect(:os.system_time(:millisecond)))
  #    Process.unlink(node_pid)
  #    if Process.alive? node_pid do
  #      GenServer.stop(node_pid, :normal)
  #    else
  #      Logger.warn("Process id: #{inspect node_pid} already dead")
  #    end
  #
  #    {:noreply, state}
  #  end

end