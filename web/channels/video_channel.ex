defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # each socket holds it's own state in
  # socket.assigns (typically a map)

  def join("videos:" <> video_id, _params, socket) do
    :timer.send_interval(5_000, :ping)
    {:ok, socket}
  end

  # handle new_annotation events pushed from client
  def handle_in("new_annotation", params, socket) do
    # then broadcast this event to all clients on this topic
    # 3 args: socket, event_name, payload
    broadcast! socket, "new_annotation", %{
      user: %{username: "anon"},
      body: params["body"],
      at: params["at"]
    }

    {:reply, :ok, socket}
  end

  # callback invoked whenever msg reaches the channel
  # essentially a loop
  # def handle_info(:ping, socket) do
  #   count = socket.assigns[:count] || 1
  #   push socket, "ping", %{count: count}

  #   # socket is transformed (increment count) using assign function
  #   {:noreply, assign(socket, :count, count + 1)}
  # end
end