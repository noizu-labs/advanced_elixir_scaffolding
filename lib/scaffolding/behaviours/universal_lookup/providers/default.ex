#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UniversalLookup do
  @table Application.get_env(:noizu_advanced_scaffolding, :universal_reference_table, Noizu.AdvancedScaffolding.Database.UniversalLookup.Table)
  @lookup_table Application.get_env(:noizu_advanced_scaffolding, :universal_reference_lookup_table, Noizu.AdvancedScaffolding.Database.UniversalReverseLookup.Table)
  
  def register(ref, uid) do
    struct(@table, [identifier: ref, universal_identifier: uid]) |> @table.write!
    struct(@lookup_table, [identifier: uid, ref: ref]) |> @lookup_table.write!
  end
  
  def lookup({:ref, _, _id} = ref) do
    case @table.read!(ref) do
      %{__struct__: @table, universal_identifier: id} -> {:ok, id}
      _ -> {:error, :not_found}
    end
  end

  def reverse_lookup(v) do
    case @lookup_table.read!(v) do
      %{__struct__: @lookup_table, ref: ref} -> {:ok, ref}
      _ -> {:error, :not_found}
    end
  end
end