defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # each socket holds it's own state in
  # socket.assigns (typically a map)

  def join("videos:" <> video_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Repo.get!(Rumbl.Video, video_id)

    annotations = Repo.all(
      from a in assoc(video, :annotations),
      where: a.id > ^last_seen_id,
      order_by: [asc: a.at, asc: a.id],
      limit: 200,
      preload: [:user]
    )

    resp = %{annotations: Phoenix.View.render_many(annotations, Rumbl.AnnotationView, "annotation.json")}

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  # make sure all incoming events have current_user
  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # handle new_annotation events pushed from client
  def handle_in("new_annotation", params, user, socket) do
    changeset =
      # build association to user and set up Annotation changeset
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

      case Repo.insert(changeset) do
        {:ok, annotation} ->
          # then broadcast this event to all clients on this topic
          # 3 args: socket, event_name, payload
          broadcast! socket, "new_annotation", %{
            id: annotation.id,
            user: Rumbl.UserView.render("user.json", %{user: user}),
            body: annotation.body,
            at: annotation.at
          }
          {:reply, :ok, socket}
        {:error, changeset} ->
          {:reply, {:error, %{errors: changeset}}, socket}
      end
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