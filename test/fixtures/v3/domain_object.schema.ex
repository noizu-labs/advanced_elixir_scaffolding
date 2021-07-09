defmodule Noizu.Scaffolding.Test.Fixture.V3.DomainObject.Schema do
  require Noizu.DomainObject
  alias Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default, as: Provider

  Noizu.DomainObject.noizu_scaffolding_schema(app: :jetzy, base_prefix: Jetzy, database_prefix: JetzySchema.MySQL) do

  end

  def __nmid_index_list__() do
    %{
      Noizu.Scaffolding.Test.Fixture.V3.Foo.Entity => 1,
    }
  end

end

#--------------------------------
#
#--------------------------------
defimpl Noizu.ERP, for: BitString do
  def ref(sref), do: Noizu.Scaffolding.Test.Fixture.V3.DomainObject.Schema.parse_sref(sref)
  def id(sref), do: ref(sref) |> Noizu.ERP.id()
  def sref("ref." <> _ = sref), do: sref
  def sref(_), do: nil
  def entity(sref, options \\ nil), do: Noizu.ERP.entity(ref(sref), options)
  def entity!(sref, options \\ nil), do: Noizu.ERP.entity!(ref(sref), options)
  def record(sref, options \\ nil), do: Noizu.ERP.record(ref(sref), options)
  def record!(sref, options \\ nil), do: Noizu.ERP.record!(ref(sref), options)
end