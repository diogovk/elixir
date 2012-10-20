defmodule Mix.SCM do
  use Behaviour

  @moduledoc """
  This module provides helper functions and defines the
  behavior required by any SCM used by mix.
  """

  @doc """
  This behavior function should retrieve an atom representing
  the SCM key. In the dependency opts, a value for the given
  must be found since it is used to print information about
  the requested dependency.
  """
  defcallback key

  @doc """
  This behavior function receives a keyword list of `opts`
  and should return an updated list in case the SCM consumes
  the available options. For example, when a developer specifies
  a dependency:

      { "foo", "0.1.0", github: "foo/bar" }

  Each registered SCM will be asked if they consume this dependency,
  receiving [github: "foo/bar"] as argument. Since this option makes
  sense for the Git SCM, it will return an update list of options
  while other SCMs would simply return nil.
  """
  defcallback consumes?(opts)

  @doc """
  This behavior function receives a `path`, `opts` and returns
  a boolean if the dependency is available.
  """
  defcallback available?(path, opts)

  @doc """
  This behavior function checks out dependencies.

  If the dependency is locked, a lock is received in `opts`
  and the repository must be check out at the lock. Otherwise,
  no lock is given and the repository can be checked out
  to the latest version.
  """
  defcallback checkout(path, opts)

  @doc """
  This behavior function updates dependencies. It may be
  called by `deps.get` or `deps.update`.

  In the first scenario, a lock is received in `opts` and
  the repository must be updated to the lock. In the second,
  no lock is given and the repository can be updated freely.

  It must return the current lock.
  """
  defcallback update(path, opts)

  @doc """
  This behavior function checks if the dependency is locked and
  the current repository version matches the lock. Note that some
  SCMs do not require a lock, for such, this function can simply
  return true.
  """
  defcallback check?(path, opts)

  @doc """
  Receives two options and must return true if the refer to the
  same repository.
  """
  defcallback match?(opts1, opts2)

  @doc """
  This behavior function should clean the given dependency.
  """
  defcallback clean(path, opts)

  @doc """
  Returns all available SCM.
  """
  def available do
    Mix.Server.call(:scm)
  end

  @doc """
  Register the scm repository with the given `key` and `mod`.
  """
  def register(mod) when is_atom(mod) do
    Mix.Server.cast({ :add_scm, mod })
  end

  @doc """
  Register builtin SCMs.
  """
  def register_builtin do
    register Mix.SCM.Git
    register Mix.SCM.Raw
  end
end
