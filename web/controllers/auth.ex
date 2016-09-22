defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  alias Rumbl.Router.Helpers

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  # call receives :repo from init
  def call(conn, repo) do
    # check if user_id is in session
    user_id = get_session(conn, :user_id)
    cond do
      # if current_user already there, return conn as it is
      user = conn.assigns[:current_user] -> conn
      # if no current_user, get from session user_id
      user = user_id && repo.get(Rumbl.User, user_id) ->
        assign(conn, :current_user, user)
      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Rumbl.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw() #simulate password check with variable timing
        {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    configure_session(conn, drop: true)
    # drops whole session at the end of request
    # keep session but delete user_id
    # delete_session(conn, :user_id)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end