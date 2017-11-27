defmodule PhxAdmin.AdminController do
  @moduledoc false
  use PhxAdmin.Web, :controller
  require Logger

  plug :set_theme
  plug :set_layout

  def page(conn, params) do
    page = Map.get(params, "page", "dashboard")
    defn = get_registered_by_controller_route!(conn, page)
    conn =  assign(conn, :defn, defn)
    contents = defn.__struct__.page_view(conn)

    render(conn, "admin.html", html: contents, resource: nil, scope_counts: [],
      filters: (if false in defn.index_filters, do: false, else: defn.index_filters))
  end
  def dashboard(conn, params) do
    page(conn, Map.put(params, "page", "dashboard"))
  end

  def select_theme(conn, %{"id" => id} = params) do
    {id, _} = Integer.parse(id)
    {_, theme} = Application.get_env(:phx_admin, :theme_selector, []) |> Enum.at(id)
    loc = Map.get(params, "loc", admin_path()) |> URI.parse |> Map.get(:path)

    Application.put_env :phx_admin, :theme, theme
    redirect conn, to: loc
  end

  def switch_user(conn, %{"id" => id} = params) do
    {id, _} = Integer.parse(id)
    current_user = PhxAdmin.Authentication.current_user(conn)
    repo = Application.get_env(:phx_admin, :repo)
    user = repo.get current_user.__struct__, id
    require Logger
    loc = Map.get(params, "loc", admin_path()) |> URI.parse |> Map.get(:path)
    {mod, fun} = Application.get_env :phx_admin, :logout_user
    apply mod, fun, [conn]
    conn = conn |> assign(:current_user, user)
    {mod, fun} = Application.get_env :phx_admin, :login_user
    apply(mod, fun, [conn, user, params])
    |> redirect(to: loc)
  end
end
