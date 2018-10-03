defmodule GS.Neighbors do
    require Logger
    '''
    main
        Calls different functions as required by a topology and creates a registry {node: [neighbors]} eg: {178: [{9, 7, 1}, {7, 7, 1}, {8, 8, 1}, {8, 6, 1}, {8, 7, 2}, {8, 7, 0}]}
    
    create_registry(1200) (number of nodes from the user input)
        Creates a registry starting from node 0 to the maximum possible number of nodes
    
    get_neighbors("3D", 999, 10) (topology, maximum possible number of nodes for that topology, maximum number of coordinates for that topology)
        Gets neighbors for a particular node
        Returns a list
    '''
    
    def main(topology, num) do

        case topology do
            "3D" -> 
                max_axis_coord = RC.nth_root(3, num) |> Kernel.trunc
                possible_num_of_nodes = :math.pow(max_axis_coord,3) |> Kernel.trunc
                create_registry("3D",possible_num_of_nodes, max_axis_coord)

                Registry.start_link(keys: :unique, name: Registry.NeighReg)
                for node <- 0..(possible_num_of_nodes-1) do
                    neighbors = get_neighbors("3D",node, max_axis_coord)
                    Registry.register(Registry.NeighReg, node, neighbors)
                end

            "torus" -> 
                max_axis_coord = RC.nth_root(2, num) |> Kernel.trunc
                possible_num_of_nodes = :math.pow(max_axis_coord,2) |> Kernel.trunc
                create_registry("torus",possible_num_of_nodes, max_axis_coord)

                Registry.start_link(keys: :unique, name: Registry.NeighReg)
                for node <- 0..(possible_num_of_nodes-1) do
                    neighbors = get_neighbors("torus",node, max_axis_coord)
                    Registry.register(Registry.NeighReg, node, neighbors)
                end

            "imp2D" ->
                num = if rem(num,2)==0, do: num, else: (num-1)
                Registry.start_link(keys: :unique, name: Registry.NeighReg) 
                randoms_remaining = []
                randoms_remaining = 
                for i <- 0..(num-1) do 
                    randoms_remaining++i
                end

                create_registry("imp2D", randoms_remaining, num)

            "line" ->
                Registry.start_link(keys: :unique, name: Registry.NeighReg) 
                remaining = []
                remaining = 
                for i <- 0..(num-1) do 
                    remaining++i
                end
                # IO.inspect remaining
                create_registry("line", remaining, num)
            
            "full" -> 
                Registry.start_link(keys: :unique, name: Registry.NeighReg) 
                nodes = []
                nodes = 
                for i <- 0..(num-1) do 
                    nodes++i
                end

                for i <- 0..(num-1) do
                    neighs = List.delete_at(nodes,i)
                    Registry.register(Registry.NeighReg, i, neighs)
                end

            "rand2D" -> 
                create_registry("rand2D", num)
                
        end
    end

    def create_registry("3D",_, max_axis_coord) do
    
        Registry.start_link(keys: :unique, name: Registry.CoordReg)
        for k <- 0..(max_axis_coord-1) do
            for j <- 0..(max_axis_coord-1) do
                for i <- 0..(max_axis_coord-1) do
                    # Create the node using Genserver start link
                    IO.inspect "#{((k*(:math.pow(max_axis_coord,2)))+(j*max_axis_coord)+(i*1))}"
                    Registry.register(Registry.CoordReg, Kernel.trunc((k*(:math.pow(max_axis_coord,2)))+(j*max_axis_coord)+(i*1)), {i,j,k})
                end
            end
        end
    end

    def create_registry("torus",_, max_axis_coord) do
    
        Registry.start_link(keys: :unique, name: Registry.CoordReg)
            for j <- 0..(max_axis_coord-1) do
                for i <- 0..(max_axis_coord-1) do
                    # Create the node using Genserver start link
                    IO.inspect "#{((j*max_axis_coord)+(i*1))}"
                    Registry.register(Registry.CoordReg, Kernel.trunc((j*max_axis_coord)+(i*1)), {i,j})
                end
            end
    end

    def create_registry("imp2D",remaining, _) when length(remaining)==0 do
        IO.puts "No more nodes remaining"
    end

    def create_registry("imp2D",remaining, num) do
        [node_selected|remaining] = remaining
        node_selected_neighs = get_neighbors("imp2D",node_selected, num)
        random_selected = remaining
        |> Enum.random
        remaining = List.delete(remaining,random_selected)
        # IO.inspect remaining

        
        neighs = List.insert_at(node_selected_neighs, -1, random_selected) |> Enum.uniq
        
        Registry.register(Registry.NeighReg, node_selected, neighs)

        random_selected_neighs = get_neighbors("imp2D",random_selected, num)
        neighs = List.insert_at(random_selected_neighs, -1, node_selected) |> Enum.uniq
        Registry.register(Registry.NeighReg, random_selected, neighs)

        create_registry("imp2D",remaining, num)
    end

    def create_registry("line", remaining, _) when length(remaining)==0 do
        IO.inspect "No more nodes"
    end

    def create_registry("line", remaining, num) do
        [node_selected|remaining] = remaining
        node_selected_neighs = get_neighbors("line", node_selected, num)

        Registry.register(Registry.NeighReg, node_selected, node_selected_neighs)

        create_registry("line",remaining, num)
    end
    
    def create_registry("rand2D",num) do
        Registry.start_link(keys: :unique, name: Registry.CoordReg)
        Registry.start_link(keys: :unique, name: Registry.NeighReg)
        Enum.each(0..(num-1), fn node_id -> 
            Registry.register(Registry.CoordReg, get_random(), node_id)
        end)

        coords_in_reg = Registry.keys(Registry.CoordReg, self())

        Enum.each(coords_in_reg, fn coord ->
            [{_, current_node_id}] = Registry.lookup(Registry.CoordReg, coord)
            # Logger.debug("current node id: " <> inspect(current_node_id))
            # Logger.debug("current node id lookup: " <> inspect(Registry.lookup(Registry.CoordReg, coord)))
            
            other_coords_in_reg = List.delete(coords_in_reg, coord) 
            # Logger.debug("Other coords in reg: " <> inspect(other_coords_in_reg))

            neighs = 
            Enum.filter(other_coords_in_reg, fn other_coord -> 
                calculate_distance(coord, other_coord) < 0.1 
            end)
            # Logger.debug("Neighs filter list: " <> inspect(neighs))

            neighs = 
            if length(neighs) == 0 do 
                List.insert_at(neighs, -1, coord)
            else
                neighs
            end

            neigh_node_ids = 
            Enum.map(neighs, fn neigh_coord -> 
                [{_,neigh_node_id}] = Registry.lookup(Registry.CoordReg, neigh_coord)
                # Logger.debug("Neigh node id: " <> inspect(neigh_node_id))
                # Logger.debug("Neigh node id lookup: " <> inspect(Registry.lookup(Registry.CoordReg, neigh_coord)))
                neigh_node_id
            end)

            # Logger.debug("Neigh node ids: " <> inspect(neigh_node_ids))
            Registry.register(Registry.NeighReg, current_node_id, neigh_node_ids)
        end)
    end
    def calculate_distance({x1,y1}, {x2,y2}) do
        :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
    end

    def get_random() do
        {:rand.uniform(), :rand.uniform()}
    end
    

    def get_neighbors("3D", node, mac) do
        
        # node: <PID>
                [{_,coord}] = Registry.lookup(Registry.CoordReg, node)
                # coord {i,j,k}
                neighbors = []

                {i,j,k} = coord
                neighbors = 
                case i+1 >= 0 and i+1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i+1,j,k}, mac))
                    false -> neighbors
                end
                neighbors = 
                case i-1 >= 0 and i-1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i-1,j,k}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j+1 > 0 and j+1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i,j+1,k}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j-1 >= 0 and j-1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i,j-1,k}, mac))
                    false -> neighbors
                end
                neighbors = 
                case k+1 > 0 and k+1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i,j,k+1}, mac))
                    false -> neighbors
                end
                neighbors = 
                case k-1 >= 0 and k-1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("3D", {i,j,k-1}, mac))
                    false -> neighbors
                end

                neighbors |> Enum.uniq()
    end

    def get_neighbors("torus", node, mac) do
        
        # node: <PID>
                [{_,coord}] = Registry.lookup(Registry.CoordReg, node)
                # coord {i,j,k}
                neighbors = []

                {i,j} = coord
                neighbors = 
                case i+1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {i+1,j}, mac))
                    false -> neighbors
                end
                neighbors = 
                case i+1 == mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {0,j}, mac))
                    false -> neighbors
                end
                neighbors = 
                case i-1 >= 0 do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {i-1,j}, mac))
                    false -> neighbors
                end
                neighbors = 
                case i-1 == -1 do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {(mac-1),j}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j+1 < mac do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {i,j+1}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j+1 == mac do
                    true -> List.insert_at(neighbors,-1,coords_to_node("torus", {i,0}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j-1 >= 0 do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {i,j-1}, mac))
                    false -> neighbors
                end
                neighbors = 
                case j-1 == -1 do
                    true -> List.insert_at(neighbors, -1, coords_to_node("torus", {i,(mac-1)}, mac))
                    false -> neighbors
                end

                neighbors |> Enum.uniq()
    end

    def get_neighbors("imp2D",node, no) do
        neighs = [] 
        neighs = 
        cond do
            node == 0 -> List.insert_at(neighs, -1, (node+1))
            node == (no-1) -> List.insert_at(neighs, -1, (node-1))
            true -> 
                List.insert_at(neighs, -1, (node+1))
                |> List.insert_at(-1, (node-1)) 
        end
        neighs |> Enum.uniq()
    end

    def get_neighbors("line",node, no) do
        neighs = [] 
        neighs = 
        cond do
            node == 0 -> List.insert_at(neighs, -1, (node+1))
            node == (no-1) -> List.insert_at(neighs, -1, (node-1))
            true -> 
                List.insert_at(neighs, -1, (node+1))
                |> List.insert_at(-1, (node-1)) 
        end
        neighs |> Enum.uniq()
    end

    def coords_to_node("torus", coord, mac) do
        (elem(coord,0) * 1) + (elem(coord,1)*mac)
    end
    def coords_to_node("3D", coord, mac) do
        (elem(coord,0) * 1) + (elem(coord,1)*mac + (elem(coord,2)*:math.pow(mac,2)))
        |> Kernel.trunc
    end

    def lookitup() do
        for i <- 1..100 do
            # [{_,list}]  = Registry.lookup(Registry.NeighReg, i)
            Logger.debug("length: " <> inspect(Registry.lookup(Registry.NeighReg, i)))
        end
    end
end

defmodule RC do
    def nth_root(n, x, precision \\ 1.0e-5) do
        f = fn(prev) -> ((n - 1) * prev + x / :math.pow(prev, (n-1))) / n end
        fixed_point(f, x, precision, f.(x))
    end
    
    defp fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
    defp fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))
end

# GS.Neighbors.main("rand2D",10000)
# GS.Neighbors.lookitup()