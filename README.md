# Gossip Simulator

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gs, "~> 0.1.0"}
  ]
end
```

## Execute

### Linux

    mix escript.build && ./gs numNodes topology algorithm

### Windows
     Powershell
     mix escript.build ; escript.exe gs <numNodes> <topology> <algorithm> <num_kill_nodes> <kill_type>

     CMD
     mix escript.build && escript.exe gs numNodes topology algorithm

     For e.g. mix compile; mix escript.build ;  escript.exe gs 1000 full gossip 20 :normal

<kill_type> argument can be :normal for expected shutdown and :kill for unexpected failure simulation


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gs](https://hexdocs.pm/gs).

