defmodule Mix.Tasks.Compile do
  use Mix.Task

  @shortdoc "Compile source files"

  @moduledoc """
  A meta task that compile source files. It simply runs the
  compilers registered in your project. At the end of compilation
  it ensures load paths are set.

  ## Configuration

  * `:compilers` - compilers to be run, defaults to:

      [:elixir, :app]

    It can be configured to handle custom compilers, for example:

      [compilers: [:elixir, :mycompiler, :app]]

  ## Common configuration

  The following options are usually shared by different compilers:

  * `:source_paths` - directories to find source files.
    Defaults to `["lib"]`, can be configured as:

        [source_paths: ["lib", "other"]]

  * `:compile_path` - directory to output compiled files.
    Defaults to `"ebin"`, can be configured as:

        [compile_path: "ebin"]

  * `:compile_first` - which files need to be compiled first.
    They need to be a subset of the files found in `source_paths`.

        [compile_first: ["lib/foo.ex", "lib/bar.ex"]]

  * `:watch_exts` - extensions to watch in order to trigger
     a compilation:

        [watch_exts: [:ex, :eex]]

  * `:compile_exts` - extensions to compile whenever there
    is a change:

        [compile_exts: [:ex]]

  ## Command line options

  * `--list` - List all enabled compilers.

  """
  def run(["--list"]) do
    Mix.Task.load_all

    shell   = Mix.shell
    modules = Mix.Task.all_modules

    docs = lc module inlist modules,
              task = Mix.Task.task_name(module),
              match?("compile." <> _, task),
              doc = Mix.Task.shortdoc(module) do
      { task, doc }
    end

    max = Enum.reduce docs, 0, fn({ task, _ }, acc) ->
      max(size(task), acc)
    end

    sorted = Enum.qsort(docs)

    Enum.each sorted, fn({ task, doc }) ->
      shell.info format('mix ~-#{max}s # ~s', [task, doc])
    end

    shell.info "\nEnabled compilers: #{Enum.join get_compilers, ", "}"
  end

  def run(args) do
    Mix.Task.run "loadpaths", args

    changed = Enum.reduce get_compilers, false, fn(compiler, acc) ->
      res = Mix.Task.run "compile.#{compiler}", args
      acc or res != :noop
    end

    # If any of the tasks above returns something different
    # than :noop, it means they produced something, so we
    # touch the common target `compile_path`. Notice that
    # we choose :noop since it is also the value returned
    # by a task that we already invoked.
    if changed, do: File.touch Mix.project[:compile_path]
  end

  defp get_compilers do
    Mix.project[:compilers] || if Mix.Project.get do
      [:elixir, :app]
    else
      [:elixir]
    end
  end

  defp format(expression, args) do
    :io_lib.format(expression, args) /> iolist_to_binary
  end
end
