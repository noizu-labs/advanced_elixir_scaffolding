defmodule Noizu.AdvancedScaffolding.Internal.Core.Repo.Implementation.Default do


  #-----------------
  # has_permission
  #-------------------
  def has_permission?(_m, _repo, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission?(_m, _repo, _permission, _context, _options), do: false

  #-----------------
  # has_permission!
  #-------------------
  def has_permission!(_m, _repo, _permission, %{auth: auth}, _options) do
    auth[:permissions][:admin] || auth[:permissions][:system] || false
  end
  def has_permission!(_m, _repo, _permission, _context, _options), do: false



end
