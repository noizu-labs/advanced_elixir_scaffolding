defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider do

  def id(_, %{identifier: id}) do
    id
  end
  def id(_, _ref) do
    nil
  end
  def ref(m, %{identifier: id}), do: {:ref, m, id}
  def ref(_, _ref) do
    nil
  end
  def sref(m, %{identifier: id}), do: "ref.#{m.__sref__()}.#{id}"
  def sref(_, _ref) do
    nil
  end
  def entity(m, %{__struct__: m} = ref, _), do: ref
  def entity(_, _ref, _options) do
    nil
  end
  def entity!(m, %{__struct__: m} = ref, _), do: ref
  def entity!(_, _ref, _options) do
    nil
  end
  def record(_, _ref, _options) do
    nil
  end
  def record!(_, _ref, _options) do
    nil
  end

  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__erp_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider


      #-----------------------------------
      # support meta
      #-----------------------------------
      def __sref__(), do: @__nzdo__sref
      def __erp__(), do: __MODULE__

      #-----------------------------------
     # ERP
     #-----------------------------------
     def id(ref), do: @__nzdo__erp_imp.id(__MODULE__, ref)
     def ref(ref), do: @__nzdo__erp_imp.ref(__MODULE__, ref)
     def sref(ref), do: @__nzdo__erp_imp.sref(__MODULE__, ref)
     def entity(ref, options \\ nil), do: @__nzdo__erp_imp.entity(__MODULE__, ref, options)
     def entity!(ref, options \\ nil), do: @__nzdo__erp_imp.entity!(__MODULE__, ref, options)
     def record(ref, options \\ nil), do: @__nzdo__erp_imp.record(__MODULE__, ref, options)
     def record!(ref, options \\ nil), do: @__nzdo__erp_imp.record!(__MODULE__, ref, options)

     defoverridable [
       id: 1,
       ref: 1,
       sref: 1,
       entity: 1,
       entity: 2,
       entity!: 1,
       entity!: 2,
       record: 1,
       record: 2,
       record!: 1,
       record!: 2,
       __sref__: 0,
       __erp__: 0
     ]
    end
  end

end
