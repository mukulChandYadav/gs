defmodule GS.Master do
  @moduledoc false

  require Logger

  use GenServer

  def start_link(opts) do
    Logger.debug("Inside start_link " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    GenServer.start_link(__MODULE__, :ok,  opts)
  end

  def init(opts) do
    {:ok, %{}}
  end

  def handle_call({:process, opts}, _from, state) do
    Logger.debug("Inside init " <> inspect(__MODULE__) <> " " <> "with options: " <> inspect(opts))
    commandline_arg = opts

    Logger.debug("commmand line_arg" <> inspect(commandline_arg))
    [head | tail] = commandline_arg
    num_nodes = String.to_integer(head)
    [head | tail] = tail
    topology = head
    [head | tail] = tail
    algorithm = head

    Logger.debug("commmand line_arg nodes - " <> inspect(num_nodes) <> " topology - " <> inspect(topology) <> " algo - " <> inspect(algorithm))

    # Create node registry <node_id, node_info>
    Registry.start_link(keys: :unique, name: GS.Registry.NodeInfo)

    # Populate neighbor registry
    GS.Neighbors.main(topology, num_nodes)
    node_ids = Registry.keys(Registry.NeighReg, self())
    Logger.debug("Prepared node_ids" <> inspect(node_ids))

    node_info_list = Enum.map(
      node_ids,
      fn x ->
        {:ok, agent_node_pid} = GS.Node.start_link([x, algorithm, topology])
        #node_info = %GS.NodeInfo{node_id: x, termination_timestamp: 0, node_state: %{}, node_pid: agent_node_pid}
        Agent.update(
          agent_node_pid,
          fn x ->
            %{x | node_pid: agent_node_pid}
          end
        )
        node_info = Agent.get(agent_node_pid, fn x-> x end)

        Registry.register(GS.Registry.NodeInfo, x, node_info)
        node_info
      end
    )

    Logger.debug("node_list" <> inspect(node_info_list))

    master_pid = self()
    # Send message to random node

    #TODO: Capture current start timestamp
    start_timestamp = :os.system_time(:millisecond)

    random_seed_node = Enum.random(node_info_list)
    Logger.debug("Calling random node " <> inspect(random_seed_node.node_pid))

    msg =
      case algorithm do
        "gossip" ->
          %{}

        "push_sum" ->
          random_seed_node.node_state
      end

    GS.Node.send_msg(random_seed_node.node_id, master_pid, algorithm, msg)

    end_timestamp = :os.system_time(:millisecond)

    time_interval = end_timestamp - start_timestamp
    Logger.info("Time taken: "<> inspect(time_interval) <>"ms")
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end