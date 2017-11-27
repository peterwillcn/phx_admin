defmodule TestExAdmin.Repo do
  use Ecto.Repo,  otp_app: :phx_admin
  use Scrivener, page_size: 10
end
