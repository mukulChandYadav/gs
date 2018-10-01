defmodule Neighbors do
    
    '''
    main
        Calls different functions as required by a topology and creates a registry {node: [neighbors]} eg: {178: [{9, 7, 1}, {7, 7, 1}, {8, 8, 1}, {8, 6, 1}, {8, 7, 2}, {8, 7, 0}]}
    
    create_registry(1200) (number of nodes from the user input)
        Creates a registry starting from node 0 to the maximum possible number of nodes
    
    get_neighbors("3d", 999, 10) (topology, maximum possible number of nodes for that topology, maximum number of coordinates for that topology)
        Gets neighbors for a particular node
        Returns a list
    '''
    
    def main(topology, num) do

        case topology do
            "3d" -> 
                max_axis_coord = RC.nth_root(3, num) |> Kernel.trunc
                possible_num_of_nodes = :math.pow(max_axis_coord,3) |> Kernel.trunc
                Neighbors.create_registry("3d",possible_num_of_nodes, max_axis_coord)

                Registry.start_link(keys: :unique, name: Registry.NeighReg)
                for node <- 0..(possible_num_of_nodes-1) do
                    neighbors = Neighbors.get_neighbors("3d",node, max_axis_coord)
                    Registry.register(Registry.NeighReg, node, neighbors)
                end

            "torus" -> 
                max_axis_coord = RC.nth_root(2, num) |> Kernel.trunc
                possible_num_of_nodes = :math.pow(max_axis_coord,2) |> Kernel.trunc
                Neighbors.create_registry("torus",possible_num_of_nodes, max_axis_coord)

                Registry.start_link(keys: :unique, name: Registry.NeighReg)
                for node <- 0..(possible_num_of_nodes-1) do
                    neighbors = Neighbors.get_neighbors("torus",node, max_axis_coord)
                    Registry.register(Registry.NeighReg, node, neighbors)
                end

            "imp2D" ->
                num = if rem(num,2)==0, do: num, else: (num-1)
                Registry.start_link(keys: :unique, name: Registry.NeighReg) 
                for node <- 1..num do
                    the_random_neigh = :rand.uniform
                end

        end
    end

    def create_registry("3d",num, max_axis_coord) do
    
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
    def create_registry("torus",num, max_axis_coord) do
    
        Registry.start_link(keys: :unique, name: Registry.CoordReg)
            for j <- 0..(max_axis_coord-1) do
                for i <- 0..(max_axis_coord-1) do
                    # Create the node using Genserver start link
                    IO.inspect "#{((j*max_axis_coord)+(i*1))}"
                    Registry.register(Registry.CoordReg, Kernel.trunc((j*max_axis_coord)+(i*1)), {i,j})
                end
            end
    end

    def get_neighbors("3d", node, mac) do
        
        # node: <PID>
                [{_,coord}] = Registry.lookup(Registry.CoordReg, node)
                # coord {i,j,k}
                neighbors = []

                {i,j,k} = coord
                neighbors = 
                case i+1 >= 0 and i+1 < mac do
                    true -> List.insert_at(neighbors, -1, {i+1,j,k})
                    false -> neighbors
                end
                neighbors = 
                case i-1 >= 0 and i-1 < mac do
                    true -> List.insert_at(neighbors, -1, {i-1,j,k})
                    false -> neighbors
                end
                neighbors = 
                case j+1 > 0 and j+1 < mac do
                    true -> List.insert_at(neighbors, -1, {i,j+1,k})
                    false -> neighbors
                end
                neighbors = 
                case j-1 >= 0 and j-1 < mac do
                    true -> List.insert_at(neighbors, -1, {i,j-1,k})
                    false -> neighbors
                end
                neighbors = 
                case k+1 > 0 and k+1 < mac do
                    true -> List.insert_at(neighbors, -1, {i,j,k+1})
                    false -> neighbors
                end
                neighbors = 
                case k-1 >= 0 and k-1 < mac do
                    true -> List.insert_at(neighbors, -1, {i,j,k-1})
                    false -> neighbors
                end

                neighbors
    end

    def get_neighbors("torus", node, mac) do
        
        # node: <PID>
                [{_,coord}] = Registry.lookup(Registry.CoordReg, node)
                # coord {i,j,k}
                neighbors = []

                {i,j} = coord
                neighbors = 
                case i+1 < mac do
                    true -> List.insert_at(neighbors, -1, {i+1,j})
                    false -> neighbors
                end
                neighbors = 
                case i+1 == mac do
                    true -> List.insert_at(neighbors, -1, {0,j})
                    false -> neighbors
                end
                neighbors = 
                case i-1 >= 0 do
                    true -> List.insert_at(neighbors, -1, {i-1,j})
                    false -> neighbors
                end
                neighbors = 
                case i-1 == -1 do
                    true -> List.insert_at(neighbors, -1, {(mac-1),j})
                    false -> neighbors
                end
                neighbors = 
                case j+1 < mac do
                    true -> List.insert_at(neighbors, -1, {i,j+1})
                    false -> neighbors
                end
                neighbors = 
                case j+1 == mac do
                    true -> List.insert_at(neighbors,-1,{i,0})
                    false -> neighbors
                end
                neighbors = 
                case j-1 >= 0 do
                    true -> List.insert_at(neighbors, -1, {i,j-1})
                    false -> neighbors
                end
                neighbors = 
                case j-1 == -1 do
                    true -> List.insert_at(neighbors, -1, {i,(mac-1)})
                    false -> neighbors
                end

                neighbors
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

Neighbors.main("torus",1000)
