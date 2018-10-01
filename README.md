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
     mix escript.build ; escript.exe gs numNodes topology algorithm

     CMD
     mix escript.build && escript.exe gs numNodes topology algorithm


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gs](https://hexdocs.pm/gs).

