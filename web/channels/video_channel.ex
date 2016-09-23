defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # each socket holds it's own state in
  # socket.assigns (typically a map)

  def join("videos:" <> video_id, _params, socket) do
    :timer.send_interval(5_000, :ping)
    {:ok, socket}
  end

  # callback invoked whenever msg reaches the channel
  # essentially a loop
  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}

    # socket is transformed (increment count) using assign function
    {:noreply, assign(socket, :count, count + 1)}
  end
end