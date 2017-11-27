defmodule PhxAdmin.TemplateView do
  @moduledoc false
  use PhxAdmin.Web, :view
  # import PhxAdmin.Authentication

  def site_title do
    case Application.get_env(:phx_admin, :module) |> Module.split do
      [_, title | _] -> title
      [title] -> title
      _ -> "PhxAdmin"
    end
  end

  def check_for_sidebars(conn, filters, defn) do
    require Logger
    if (is_nil(filters) or filters == false) and not PhxAdmin.Sidebar.sidebars_visible?(conn, defn) do
      {false, "without_sidebar"}
    else
      {true, "with_sidebar"}
    end
  end

  def admin_static_path(conn, path) do
    theme = "/themes/" <> Application.get_env(:phx_admin, :theme, "active_admin")
    static_path(conn, "#{theme}#{path}")
  end
end
