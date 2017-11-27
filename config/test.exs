use Mix.Config

config :phx_admin, TestExAdmin.Endpoint,
  http: [port: 4001],
  secret_key_base: "HL0pikQMxNSA58DV3mf26O/eh1e4vaJDmx1qLgqBcnS14gbKu9Xn3x114D+mHYcX",
  server: true
  #debug_errors: true

config :phx_admin, TestExAdmin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex_admin_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :phx_admin,
  repo: TestExAdmin.Repo,
  module: TestExAdmin,
  modules: [
    TestExAdmin.PhxAdmin.Dashboard,
    TestExAdmin.PhxAdmin.Noid,
    TestExAdmin.PhxAdmin.User,
    TestExAdmin.PhxAdmin.Product,
    TestExAdmin.PhxAdmin.Simple,
    TestExAdmin.PhxAdmin.ModelDisplayName,
    TestExAdmin.PhxAdmin.DefnDisplayName,
    TestExAdmin.PhxAdmin.RestrictedEdit,
  ]

config :xain,
  quote: "'",
  after_callback: {Phoenix.HTML, :raw}

config :logger, level: :error

config :hound, driver: "phantomjs"
