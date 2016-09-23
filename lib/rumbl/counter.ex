defmodule Rumbl.Counter do

# Client API
  def inc(pid), do: send(pid, :inc)

  def dec(pid), do: send(pid, :dec)

  def val(pid, timeout \\ 5000) do
    ref = make_ref() # create a unique reference
    send(pid, {:val, self(), ref})

    receive do
      # ^ means rather than reassigning ref, it must match tuples that have that exact ref as defined above
      {^ref, val} -> val
    after timeout -> exit(:timeout)
    end
  end

# Server Callbacks
  def start_link(initial_val) do
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

# Private functions
  defp listen(val) do
    receive do
      :inc -> listen(val + 1)
      :dec -> listen(val - 1)
      {:val, sender, ref} ->
        send sender, {ref, val}
        listen(val)
    end
  end

end