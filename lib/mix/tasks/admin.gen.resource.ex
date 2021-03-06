defmodule Mix.Tasks.Admin.Gen.Resource do
  @moduledoc """
  Generate an PhxAdmin Resource file

  Creates a resource file used to define the administration pages
  for the auto administration feature

      mix admin.gen.resource Survey

  Creates a admin/survey.ex file.

  """

  @shortdoc "Generate a Resource file"

  use Mix.Task
  import Mix.PhxAdmin.Utils

  defmodule Config do
    @moduledoc false
    defstruct module: nil, package_path: nil, base: nil, resource: nil
  end

  def run(args) do
    parse_args(args)
    |> copy_file
  end


  defp copy_file(%Config{module: module, package_path: package_path} = config) do
    filename = Macro.underscore(module) <> ".ex"
    dest_path = Path.join web_path(), "admin"
    dest_file_path = Path.join dest_path, filename
    base = get_module()
    source_file = Path.join([package_path | ~w(priv templates admin.gen.resource resource.exs)] )
    source = source_file |> EEx.eval_file(base: base, resource: module)
    status_msg "creating", dest_file_path
    File.write! dest_file_path, source
    config
    |> struct(resource: Module.concat(base, module), base: base)
    |> display_instructions
    |> check_for_changetset
  end

  defp display_instructions(%{base: base} = config) do
    IO.puts ""
    IO.puts "Remember to update your config file with the resource module"
    IO.puts ""
    IO.puts """
        config :phx_admin, :modules, [
          #{base}.PhxAdmin.Dashboard,
          ...
          #{base}.PhxAdmin.#{config.module}
        ]

    """
    config
  end

  defp check_for_changetset(%{resource: resource} = config) do
    Code.ensure_compiled(resource)
    unless function_exported?(resource, :changeset, 2) do
      IO.puts """
      *** Warning ***
      Please make sure #{inspect resource}.changeset/2 is defined or
      define custom changesets for your resource to ensure PhxAdmin
      can create and update the resource.
      """
    end
    config
  end

  defp parse_args([module]) do
    %Config{module: module, package_path: get_package_path()}
  end

end
