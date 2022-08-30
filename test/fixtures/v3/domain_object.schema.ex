#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema do
  require Noizu.DomainObject
  #alias Noizu.ElixirScaffolding.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default, as: Provider
  
  Noizu.DomainObject.noizu_schema_info(app: :noizu_advanced_scaffolding, base_prefix: Noizu.AdvancedScaffolding, database_prefix: Noizu.AdvancedScaffolding.Database) do
    def nmid_keys(), do: __noizu_info__(:nmid_indexes)
  end

  
  def __nmid_index_list__() do
    %{
      Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity => 1,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAtom => 100,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestCompound => 200,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestHash => 300,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestAInteger=> 400,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestList => 500,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestRef => 600,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestString => 700,
      Noizu.AdvancedScaffolding.Test.Fixture.V3.TypeTestUUID => 800,
    }
  end

end

#--------------------------------
#
#--------------------------------
defimpl Noizu.ERP, for: BitString do
  def ref(sref), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.DomainObject.Schema.parse_sref(sref)
  def id(sref), do: ref(sref) |> Noizu.ERP.id()
  def sref("ref." <> _ = sref), do: sref
  def sref(_), do: nil
  def entity(sref, options \\ nil), do: Noizu.ERP.entity(ref(sref), options)
  def entity!(sref, options \\ nil), do: Noizu.ERP.entity!(ref(sref), options)
  def record(sref, options \\ nil), do: Noizu.ERP.record(ref(sref), options)
  def record!(sref, options \\ nil), do: Noizu.ERP.record!(ref(sref), options)

  def id_ok(o) do
    r = id(o)
    r && {:ok, r} || {:error, o}
  end
  def ref_ok(o) do
    r = ref(o)
    r && {:ok, r} || {:error, o}
  end
  def sref_ok(o) do
    r = sref(o)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok(o, options \\ %{}) do
    r = entity(o, options)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok!(o, options \\ %{}) do
    r = entity!(o, options)
    r && {:ok, r} || {:error, o}
  end
end
