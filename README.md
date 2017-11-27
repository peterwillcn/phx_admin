# PhxAdmin

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

Note: This version has been updated to support both Ecto 1.1 and Ecto 2.0. See [Installation](#installation) for more information.

PhxAdmin is an auto administration package for [Elixir](http://elixir-lang.org/) and the [Phoenix Framework](http://www.phoenixframework.org/), a port/inspiration of [ActiveAdmin](http://activeadmin.info/) for Ruby on Rails.

See the [docs](https://hexdocs.pm/phx_admin/) for more information.

## Support for Phoenix 1.3 phx.new Projects

This branch has experimental support for phx projects. You should be able to use this version the same as before. It will detect if your project is using the standard phx layout and place you resource appropriately.

## Couple Notes:

When when generating resources, use the `Context` namespace like so:

```bash
mix admin.gen.resource Blogs.Post
```

You may have to add a `changeset/2` to your schema file to get PhxAdmin to work out of the box. Otherwise, you will need to define custom changesets.

This version should support both the legacy and the new phx project structures. However, I have only tested phx structure.

I have tested this branch manually. However, there are a number of tests failing which I still need to fix.

## Usage

PhxAdmin is an add on for an application using the [Phoenix Framework](http://www.phoenixframework.org) to create an CRUD administration tool with little or no code. By running a few mix tasks to define which Ecto Models you want to administer, you will have something that works with no additional code.

Before using PhxAdmin, you will need a Phoenix project and an Ecto model created.

### Installation

Add phx_admin to your deps:

#### Hex

mix.exs
```elixir
  {:phx_admin, "~> 0.9.2"}
```

Add some admin configuration and the admin modules to the config file

config/config.exs
```elixir
  config :phx_admin,
  repo: MyProject.Repo,
  module: MyProjectWeb,
  modules: [
    MyProject.PhxAdmin.Dashboard,
  ]

```

Fetch and compile the dependency

```
mix do deps.get, deps.compile
```

Configure PhxAdmin:

```
mix admin.install
```

Add the admin routes

web/router.ex
```elixir
defmodule MyProject.Router do
  use MyProject.Web, :router
  use PhxAdmin.Router
  ...
  scope "/", MyProject do
    ...
  end

  # setup the PhxAdmin routes on /admin
  scope "/admin", PhxAdmin do
    pipe_through :browser
    admin_routes()
  end
```

Add the paging configuration

lib/my_project/repo.ex
```elixir
  defmodule MyProject.Repo do
    use Ecto.Repo, otp_app: :my_project
    use Scrivener, page_size: 10
  end

```

Edit your brunch-config.js file and follow the instructions that the installer appended to this file. This requires you copy 2 blocks and replace the existing blocks.

Start the application with `iex -S mix phoenix.server`

Visit http://localhost:4000/admin

You should see the default Dashboard page.

## Getting Started

### Adding an Ecto Model to PhxAdmin

To add a model, use `admin.gen.resource` mix task:

```
mix admin.gen.resource MyModel
```

Add the new module to the config file:

config/config.exs

```elixir
config :phx_admin,
  repo: MyProject.Repo,
  module: MyProjectWeb,
  modules: [
    MyProject.PhxAdmin.Dashboard,
    MyProject.PhxAdmin.MyModel,
  ]
```

Start the phoenix server again and browse to `http://localhost:4000/admin/my_model`

You can now list/add/edit/and delete `MyModel`s.

### Changesets
PhxAdmin will use your schema's changesets. By default we call the `changeset` function on your schema, although you
can configure the changeset we use for update and create seperately.

custom changeset:
```elixir
defmodule TestPhxAdmin.PhxAdmin.Simple do
  use PhxAdmin.Register

  register_resource TestPhxAdmin.Simple do
    update_changeset :changeset_update
    create_changeset :changeset_create
  end
end
```

#### Relationships

We support many-to-many and has many relationships as provided by Ecto. We recommend using cast_assoc for many-to-many relationships
and put_assoc for has-many. You can see example changesets in out [test schemas](test/support/schema.exs)

When passing in results from a form for relationships we do some coercing to make it easier to work with them in your changeset.
For collection checkboxes we will pass an array of the selected options ids to your changeset so you can get them and use put_assoc as [seen here](test/support/schema.exs#L26-L35)

In order to support has many deletions you need you to setup a virtual attribute on your schema's. On the related schema you will
need to add an _destroy virtual attribute so we can track the destroy property in the form. You will also need to cast this in your changeset. Here is an example changeset. In this scenario a User has many products and products can be deleted. We also have many roles associated.

```elxiir
defmodule TestPhxAdmin.User do
  import Ecto.Changeset
  use Ecto.Schema
  import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string
    field :active, :boolean, default: true
    has_many :products, TestPhxAdmin.Product, on_replace: :delete
    many_to_many :roles, TestPhxAdmin.Role, join_through: TestPhxAdmin.UserRole, on_replace: :delete
  end

  @fields ~w(name active email)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:email, :name])
    |> cast_assoc(:products, required: false)
    |> add_roles(params)
  end

  def add_roles(changeset, params) do
    if Enum.count(Map.get(params, :roles, [])) > 0 do
      ids = params[:roles]
      roles = TestPhxAdmin.Repo.all(from r in TestPhxAdmin.Role, where: r.id in ^ids)
      put_assoc(changeset, :roles, roles)
    else
      changeset
    end
  end
end

defmodule TestPhxAdmin.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias TestPhxAdmin.Repo

  schema "roles" do
    field :name, :string
    has_many :uses_roles, TestPhxAdmin.UserRole
    many_to_many :users, TestPhxAdmin.User, join_through: TestPhxAdmin.UserRole
  end

  @fields ~w(name)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
  end
end


defmodule TestPhxAdmin.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :_destroy, :boolean, virtual: true
    field :title, :string
    field :price, :decimal
    belongs_to :user, TestPhxAdmin.User
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, ~w(title price user_id))
    |> validate_required(~w(title price))
    |> mark_for_deletion
  end

  defp mark_for_deletion(changeset) do
    # If delete was set and it is true, let's change the action
    if get_change(changeset, :_destroy) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
```

A good blog post exisits on the Platformatec blog describing how these relationships work: http://blog.plataformatec.com.br/2015/08/working-with-ecto-associations-and-embeds/

### Customizing the index page

Use the `index do` command to define the fields to be displayed.

admin/my_model.ex
```elixir
defmodule MyProject.PhxAdmin.MyModel do
  use PhxAdmin.Register
  register_resource MyProject.MyModel do

    index do
      selectable_column()

      column :id
      column :name
      actions()     # display the default actions column
    end
  end
end
```

### Customizing the form

The following example shows how to customize the form with the `form` macro:

```elixir
defmodule MyProject.PhxAdmin.Contact do
  use PhxAdmin.Register

  register_resource MyProject.Contact do
    form contact do
      inputs do
        input contact, :first_name
        input contact, :last_name
        input contact, :email
        input contact, :category, collection: MyProject.Category.all
      end

      inputs "Groups" do
        inputs :groups, as: :check_boxes, collection: MyProject.Group.all
      end
    end
  end
end
```

### Customizing the show page

The following example illustrates how to modify the show page.

```elixir
defmodule MyProject.PhxAdmin.Question do
  use PhxAdmin.Register

  register_resource MyProject.Question do
    menu priority: 3

    show question do

      attributes_table   # display the defaults attributes

      # create a panel to list the question's choices
      panel "Choices" do
        table_for(question.choices) do
          column :key
          column :name
        end
      end
    end
  end
end
```
## Custom Types

Support for custom field types is done in two areas, rendering fields, and input controls.

### Rendering Custom Types

Use the `PhxAdmin.Render.to_string/` protocol for rendering types that are not supported by PhxAdmin.

For example, to support rendering a tuple, add the following file to your project:

```elixir
# lib/render.ex
defimpl PhxAdmin.Render, for: Tuple do
  def to_string(tuple), do: inspect(tuple)
end
```

### Input Type

Use the `:field_type_matching` config item to set the input type.

For example, given the following project:

```elixir
defmodule ElixirLangMoscow.SpeakerSlug do
  use EctoAutoslugField.Slug, from: [:name, :company], to: :slug
end

defmodule ElixirLangMoscow.Speaker do
  use ElixirLangMoscow.Web, :model
  use Arc.Ecto.Model

  alias ElixirLangMoscow.SpeakerSlug
  schema "speakers" do
    field :slug, SpeakerSlug.Type
    field :avatar, ElixirLangMoscow.Avatar.Type
  end
end
```

Add the following to your project's configuration:

```elixir
config :phx_admin,
  # ...
  field_type_matching: %{
    ElixirLangMoscow.SpeakerSlug.Type => :string,
    ElixirLangMoscow.Avatar.Type => :file
  }
```

## Theme Support

PhxAdmin supports 2 themes. The new AdminLte2 theme is enabled by default. The old ActiveAdmin theme is also supported for those that want backward compatibility.

### Changing the Theme

To change the theme to ActiveAdmin, at the following to your `config/config.exs` file:

config/config.exs
```elixir
config :phx_admin,
  theme: PhxAdmin.Theme.ActiveAdmin,
  ...
```

### Changing the AdminLte2 Skin Color

The AdminLte2 theme has a number of different skin colors including blue, black, purple, green, red, yellow, blue-light, black-light, purple-light, green-light, red-light, and yellow-light

To change the skin color to, for example, purple:

config/config.exs
```elixir
config :phx_admin,
  skin_color: :purple,
  ...
```

### Enable Theme Selector

You can add a theme selector on the top right of the menu bar by adding the following to your `config/config.exs` file:

config/config.exs
```elixir
config :phx_admin,
  theme_selector: [
    {"AdminLte",  PhxAdmin.Theme.AdminLte2},
    {"ActiveAdmin", PhxAdmin.Theme.ActiveAdmin}
  ],
  ...
```

## Authentication

PhxAdmin leaves the job of authentication to 3rd party packages. For an example of using [Coherence](https://github.com/smpallen99/coherence) checkout the [Contact Demo Project](https://github.com/smpallen99/contact_demo).

## License

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
