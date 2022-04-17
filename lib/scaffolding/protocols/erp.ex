#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defimpl Noizu.ERP, for: Any do

  def id(ref) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.id(ref)
          {:erp_handler, 0} in m.erp_handler.module_info(:exports) -> m.erp_handler.id(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def ref(ref) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.ref(ref)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.ref(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def sref(ref) do
    case ref do
      %{__struct__: m} ->
        cond do
          function_exported?(m, :__erp__, 0) -> m.__erp__.sref(ref)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.sref(ref)
          :else -> nil
        end
      _ -> nil
    end
  end

  def record(ref, options \\ nil)
  def record(ref, options) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.record(ref, options)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.record(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end



  def record!(ref, options \\ nil)
  def record!(ref, options) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.record!(ref, options)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.record!(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end




  def entity(ref, options \\ nil)
  def entity(ref, options) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.entity(ref, options)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.entity(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end


  def entity!(ref, options \\ nil)
  def entity!(ref, options) do
    case ref do
      %{__struct__: m} ->
        cond do
          {:__erp__, 0} in m.module_info(:exports) -> m.__erp__.entity!(ref, options)
          {:erp_handler, 0} in m.module_info(:exports) -> m.erp_handler.entity!(ref, options)
          :else -> nil
        end
      _ -> nil
    end
  end



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

end # end defimpl EntityReferenceProtocol, for: Map
