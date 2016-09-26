# proxy, see Programming Phoenix pg 630
require IEx

defmodule Rumbl.InfoSys do
  @backends [Rumbl.InfoSys.Wolfram]

  defmodule Result do
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends
    answer =
      backends
      |> Enum.map(&spawn_query(&1, query, limit))
      |> await_results(opts)
      |> Enum.sort(&(&1.score >= &2.score))
      |> Enum.take(limit)
    answer
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000
    timer = Process.send_after(self(), :timedout, timeout)

    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head
    receive do
      # if valid results
      {:results, ^query_ref, results} ->
        # 1. drop the monitoring of the child, flush to remove :DOWN msg
        Process.demonitor(monitor_ref, [:flush])
        # 2. add result to accumulator
        await_result(tail, results ++ acc, timeout)
      #  if invalid results
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        # recurse w/o adding anything to accumulator
        await_result(tail, acc, timeout)
      :timedout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  # break recursion if list of children is empty
  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timedout -> :ok
    after
      0 -> :ok
    end
  end
end