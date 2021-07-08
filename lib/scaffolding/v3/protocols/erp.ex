#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------



defimpl Noizu.ERP, for: Any do

  def id(ref) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.id(ref)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.id(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def ref(ref) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.ref(ref)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.ref(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def sref(ref) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.sref(ref)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.sref(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def record(ref, options \\ nil)
  def record(ref, options) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.record(ref, options)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.record(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end



  def record!(ref, options \\ nil)
  def record!(ref, options) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.record!(ref, options)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.record!(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end




  def entity(ref, options \\ nil)
  def entity(ref, options) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.entity(ref, options)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.entity(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end


  def entity!(ref, options \\ nil)
  def entity!(ref, options) do
    case ref do
      %m{} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.entity!(ref, options)
          function_exported?(m, :erp_handler, 0) -> m.erp_handler.entity!(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end

  defmacro __deriving__(module, _struct, _options) do
    quote do
      defimpl Noizu.ERP, for: unquote(module) do
        def id(%{__struct__: m} = ref), do: m.__erp__().id(ref)
        def ref(%{__struct__: m} = ref), do: m.__erp__().ref(ref)
        def sref(%{__struct__: m} = ref), do: m.__erp__().sref(ref)
        def record(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().record(ref, options)
        def record!(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().record!(ref, options)
        def entity(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().entity(ref, options)
        def entity!(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().entity!(ref, options)
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
