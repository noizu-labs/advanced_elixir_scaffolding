#=============================================
#
#=============================================
defprotocol Noizu.MySQL.Entity do
  @fallback_to_any true
  def universal_reference?(ref)
  def supported?(ref)
  def mysql_identifier(ref)
  def universal_identifier(ref)
  def ref(ref)
  def source(ref)
end

#=============================================
#
#=============================================
defimpl Noizu.MySQL.Entity, for: Any do

  defmacro __deriving__(module, struct, options) do


    quote do
      defimpl Noizu.MySQL.Entity, for: unquote(module) do
        def universal_reference?(_), do: false
        def supported?(%{__struct__: module}) do
          try do
            module.mysql_entity?()
          rescue _e -> false
          catch _e -> false
          end
        end

        def mysql_identifier(%{__struct__: module} = m) do
          if supported?(m) do
            module.mysql_identifier(m)
          end
        end
        def mysql_identifier(_), do: nil

        def universal_identifier(%{__struct__: module} = m) do
          if supported?(m) do
            module.universal_identifier(m)
          end
        end

        def ref(%{__struct__: module} = m) do
          if supported?(m) do
            module.ref(m)
          end
        end

        def source(%{__struct__: module} = m) do
          if supported?(m) do
            module.source(m)
          end
        end
      end
    end
  end


  def universal_reference?(_), do: false
  def supported?(_), do: false
  def mysql_identifier(_), do: nil
  def universal_identifier(_), do: nil
  def ref(_), do: nil
  def source(_), do: nil
end

#=============================================
#
#=============================================
defimpl Noizu.MySQL.Entity, for: BitString do
  def universal_reference?("ref.universal." <> _), do: true
  def universal_reference?(_), do: false
  def supported?(sref), do: Noizu.MySQL.Entity.supported?(Noizu.ERP.ref(sref))
  def mysql_identifier(sref), do: Noizu.MySQL.Entity.mysql_identifier(Noizu.ERP.ref(sref))
  def universal_identifier(sref), do: Noizu.MySQL.Entity.universal_identifier(Noizu.ERP.ref(sref))
  def ref(sref), do: Noizu.MySQL.Entity.ref(Noizu.ERP.ref(sref))
  def source(sref), do: Noizu.MySQL.Entity.source(Noizu.ERP.ref(sref))
end

#=============================================
#
#=============================================
defimpl Noizu.MySQL.Entity, for: Tuple do
  def universal_reference?({:ref, Noizu.UniversalReference, _}), do: true
  def universal_reference?(_), do: false

  #-----------------------------
  #
  #-----------------------------
  def supported?({:ref, module, _}) do
    try do
      module.mysql_entity?()
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?({:mysql_identifier, module, _}) do
    try do
      Module.get_attribute(module, :is_noizu_mysql_entity) || false
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?(_), do: false

  #-----------------------------
  #
  #-----------------------------
  def mysql_identifier({:mysql_identifier, _, v}), do: v
  def mysql_identifier({:ref, module, _identifier} = ref) do
    if supported?(ref) do
      module.mysql_identifier(ref)
    else
      nil
    end
  end
  def mysql_identifier(_), do: nil

  #-----------------------------
  #
  #-----------------------------
  def universal_identifier({:mysql_identifier, _module, _} = ref) do
    r = Noizu.MySQL.Entity.ref(ref)
    r != ref && universal_identifier(r)
  end
  def universal_identifier({:ref, Noizu.UniversalReference, _} = ref) do
    Noizu.UniversalReference.universal_identifier(ref)
  end
  def universal_identifier({:ref, module, _} = ref) do
    if supported?(ref) do
      case Noizu.Scaffolding.V3.Database.UniversalLookupTable.read!(ref) do
        %Noizu.Scaffolding.V3.Database.UniversalLookupTable{universal_identifier: universal_identifier} -> universal_identifier
        _ ->
          case module.universal_identifier(ref) do
            v when is_integer(v) ->
              %Noizu.Scaffolding.V3.Database.UniversalLookupTable{identifier: ref, universal_identifier: v} |> Noizu.Scaffolding.V3.Database.UniversalLookupTable.write!
              v
            _ ->
              nil
          end
      end
    else
      nil
    end
  end
  def universal_identifier(_), do: nil

  #-----------------------------
  #
  #-----------------------------
  def ref({:mysql_identifier, m, _} = ref) do
    if supported?(ref) do
      m.mysql_identifier(ref)
    else
      nil
    end
  end
  def ref({:ref, Noizu.UniversalReference, _} = ref) do
    Noizu.ERP.ref(Noizu.UniversalReference.resolve(ref))
  end
  def ref({:ref, _m, _id} = ref), do: ref
  def ref(_), do: nil


  #-----------------------------
  #
  #-----------------------------
  def source({:mysql_identifier, module, _} = ref) do
    if supported?(ref) do
      module.source(ref)
    end
  end
  def source({:ref, module, _} = ref) do
    if supported?(ref) do
      module.source(ref)
    end
  end
end

#=============================================
#
#=============================================
defimpl Noizu.MySQL.Entity, for: [Noizu.UniversalReference] do
  def universal_reference?(_), do: true
  def supported?(_), do: true
  def mysql_identifier(entity), do: Noizu.UniversalReference.mysql_identifier(entity)
  def universal_identifier(entity), do: Noizu.UniversalReference.universal_identifier(entity)
  def ref(m), do: Noizu.ERP.ref(Noizu.UniversalReference.resolve(m))
  def source(m), do: Noizu.UniversalReference.source(m)
end

#=============================================
#
#=============================================
defimpl Noizu.MySQL.Entity, for: [ Map ] do
  def universal_reference?(_), do: false
  def supported?(%{__struct__: module}) do
    try do
      module.mysql_entity?()
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?(_), do: false

  def mysql_identifier(%{__struct__: module} = m) do
    if supported?(m) do
      module.mysql_identifier(m)
    end
  end
  def mysql_identifier(_), do: nil

  def universal_identifier(%{__struct__: module} = m) do
    if supported?(m) do
      module.universal_identifier(m)
    end
  end
  def universal_identifier(_), do: nil
  def ref(%{__struct__: module} = m) do
    if supported?(m) do
      module.ref(m)
    end
  end
  def ref(_), do: nil

  def source(%{__struct__: module} = m) do
    if supported?(m) do
      module.source(m)
    end
  end
  def source(_), do: nil
end
