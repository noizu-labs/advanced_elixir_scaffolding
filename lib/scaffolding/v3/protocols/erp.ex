#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------



defimpl Noizu.ERP, for: Any do
  def id(_), do: nil
  def ref(_), do: nil
  def sref(_), do: nil
  def record(entity, options \\ nil)
  def record(_entity, _options), do: nil
  def record!(entity, options \\ nil)
  def record!(_entity, _options), do: nil
  def entity(entity, options \\ nil)
  def entity(_entity, _options), do: nil
  def entity!(entity, options \\ nil)
  def entity!(_entity, _options), do: nil

  defmacro __deriving__(module, _struct, _options) do
    quote do
      defimpl Noizu.ERP, for: unquote(module) do
        def id(%{__struct__: m} = ref), do: m.erp_handler().id(ref)
        def ref(%{__struct__: m} = ref), do: m.erp_handler().ref(ref)
        def sref(%{__struct__: m} = ref), do: m.erp_handler().sref(ref)
        def record(%{__struct__: m} = ref, options \\ nil), do: m.erp_handler().record(ref, options)
        def record!(%{__struct__: m} = ref, options \\ nil), do: m.erp_handler().record!(ref, options)
        def entity(%{__struct__: m} = ref, options \\ nil), do: m.erp_handler().entity(ref, options)
        def entity!(%{__struct__: m} = ref, options \\ nil), do: m.erp_handler().entity!(ref, options)
      end
    end
  end

end # end defimpl EntityReferenceProtocol, for: Map


defimpl Noizu.ERP, for: Map do
  def id(_), do: nil
  def ref(_), do: nil
  def sref(_), do: nil
  def record(entity, options \\ nil)
  def record(_entity, _options), do: nil
  def record!(entity, options \\ nil)
  def record!(_entity, _options), do: nil
  def entity(entity, options \\ nil)
  def entity(_entity, _options), do: nil
  def entity!(entity, options \\ nil)
  def entity!(_entity, _options), do: nil
end # end defimpl EntityReferenceProtocol, for: Map
