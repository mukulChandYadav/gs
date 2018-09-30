defmodule GS_CLI do
  @moduledoc false

    def main(args) do
      IO.inspect args
      GS.start(:normal , args)
      {opts,_,_}= OptionParser.parse(args)
      IO.inspect opts #here I just print the options
    end
  end
