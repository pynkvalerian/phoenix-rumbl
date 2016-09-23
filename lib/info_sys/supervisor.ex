defmodule Rumbl.InfoSys.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    # declare name so it's easy to call from anywhere
  end

  def init(_opts) do
    children = [
      worker(Rumbl.InfoSys, [], restart: :temporary)
    ]

    # supervise these children stated above
    supervise children, startegy: :simple_one_for_one
  end
end