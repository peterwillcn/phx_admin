defmodule TestExAdmin.Router do
  use PhxAdmin.Web, :router
  use PhxAdmin.Router


  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/admin", PhxAdmin do
    pipe_through :browser
    admin_routes()
  end
end

