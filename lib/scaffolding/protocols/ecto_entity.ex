#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

#=============================================
#
#=============================================
defprotocol Noizu.EctoEntity.Protocol do
  @fallback_to_any true
  def universal_reference?(ref)
  def supported?(ref)
  def ecto_identifier(ref)
  def universal_identifier(ref)
  def index_identifier(ref)
  def ref(ref)
  def source(ref)
end

#=============================================
#
#=============================================
defimpl Noizu.EctoEntity.Protocol, for: Any do

  defmacro __deriving__(module, _struct, _options) do
    quote do
      defimpl Noizu.EctoEntity.Protocol, for: unquote(module) do
        def universal_reference?(_), do: false
        def supported?(_), do: true
        def ecto_identifier(m), do: unquote(module).ecto_identifier(m)
        def universal_identifier(m), do: unquote(module).universal_identifier(m)
        def index_identifier(m), do: unquote(module).index_identifier(m)
        def ref(m), do: unquote(module).ref(m)
        def source(m), do: unquote(module).source(m)
      end
    end
  end


  def universal_reference?(_), do: false
  def supported?(_), do: false
  def ecto_identifier(_), do: nil
  def universal_identifier(_), do: nil
  def index_identifier(_), do: nil
  def ref(_), do: nil
  def source(_), do: nil
end

#=============================================
#
#=============================================
defimpl Noizu.EctoEntity.Protocol, for: BitString do
  def universal_reference?("ref.universal." <> _), do: true
  def universal_reference?(_), do: false
  def supported?(sref), do: Noizu.EctoEntity.Protocol.supported?(Noizu.ERP.ref(sref))
  def ecto_identifier(sref), do: Noizu.EctoEntity.Protocol.ecto_identifier(Noizu.ERP.ref(sref))
  def universal_identifier(sref), do: Noizu.EctoEntity.Protocol.universal_identifier(Noizu.ERP.ref(sref))
  def index_identifier(sref), do: Noizu.EctoEntity.Protocol.index_identifier(Noizu.ERP.ref(sref))
  def ref(sref), do: Noizu.EctoEntity.Protocol.ref(Noizu.ERP.ref(sref))
  def source(sref), do: Noizu.EctoEntity.Protocol.source(Noizu.ERP.ref(sref))
end

#=============================================
#
#=============================================
defimpl Noizu.EctoEntity.Protocol, for: Tuple do
  def universal_reference?({:ref, Noizu.DomainObject.Integer.UniversalReference, _}), do: true
  def universal_reference?(_), do: false

  #-----------------------------
  #
  #-----------------------------
  def supported?({:ref, module, _}) do
    try do
      module.ecto_entity?()
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?({:ecto_identifier, module, _}) do
    try do
      module.ecto_entity?()
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?(_), do: false

  #-----------------------------
  #
  #-----------------------------
  def ecto_identifier({:ecto_identifier, _, v}), do: v
  def ecto_identifier({:ref, module, _identifier} = ref) do
    if supported?(ref) do
      module.ecto_identifier(ref)
    else
      nil
    end
  end
  def ecto_identifier(_), do: nil

  #-----------------------------
  #
  #-----------------------------
  def universal_identifier({:ecto_identifier, _module, _} = ref) do
    r = Noizu.EctoEntity.Protocol.ref(ref)
    r != ref && universal_identifier(r)
  end
  def universal_identifier({:ref, Noizu.DomainObject.Integer.UniversalReference, _} = ref) do
    Noizu.DomainObject.Integer.UniversalReference.universal_identifier(ref)
  end
  def universal_identifier({:ref, module, _} = ref) do
    if supported?(ref) do
      module.universal_identifier(ref)
    else
      nil
    end
  end
  def universal_identifier(_), do: nil

  #-----------------------------
  #
  #-----------------------------
  def index_identifier({:ecto_identifier, _module, _} = ref) do
    r = Noizu.EctoEntity.Protocol.ref(ref)
    r != ref && index_identifier(r)
  end
  def index_identifier({:ref, Noizu.DomainObject.Integer.UniversalReference, _} = ref) do
    Noizu.DomainObject.Integer.UniversalReference.index_identifier(ref)
  end
  def index_identifier({:ref, module, _} = ref) do
    if supported?(ref) do
      module.index_identifier(ref)
    else
      nil
    end
  end
  def index_identifier(_), do: nil
  
  #-----------------------------
  #
  #-----------------------------
  def ref({:ecto_identifier, m, _} = ref) do
    if supported?(ref) do
      m.ref(ref)
    else
      nil
    end
  end
  def ref({:ref, Noizu.DomainObject.Integer.UniversalReference, _} = ref) do
    Noizu.ERP.ref(Noizu.DomainObject.Integer.UniversalReference.resolve(ref))
  end
  def ref({:ref, _m, _id} = ref), do: ref
  def ref(_), do: nil


  #-----------------------------
  #
  #-----------------------------
  def source({:ecto_identifier, module, _} = ref) do
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
defimpl Noizu.EctoEntity.Protocol, for: [Noizu.DomainObject.Integer.UniversalReference] do
  def universal_reference?(_), do: true
  def supported?(_), do: true
  def ecto_identifier(entity), do: Noizu.DomainObject.Integer.UniversalReference.ecto_identifier(entity)
  def universal_identifier(entity), do: Noizu.DomainObject.Integer.UniversalReference.universal_identifier(entity)
  def index_identifier(entity), do: Noizu.DomainObject.Integer.UniversalReference.index_identifier(entity)
  def ref(m), do: Noizu.ERP.ref(Noizu.DomainObject.Integer.UniversalReference.resolve(m))
  def source(m), do: Noizu.DomainObject.Integer.UniversalReference.source(m)
end

#=============================================
#
#=============================================
defimpl Noizu.EctoEntity.Protocol, for: [Noizu.DomainObject.UUID.UniversalReference] do
  def universal_reference?(_), do: true
  def supported?(_), do: true
  def ecto_identifier(entity), do: Noizu.DomainObject.UUID.UniversalReference.ecto_identifier(entity)
  def universal_identifier(entity), do: Noizu.DomainObject.UUID.UniversalReference.universal_identifier(entity)
  def index_identifier(entity), do: Noizu.DomainObject.UUID.UniversalReference.index_identifier(entity)
  def ref(m), do: Noizu.ERP.ref(Noizu.DomainObject.UUID.UniversalReference.resolve(m))
  def source(m), do: Noizu.DomainObject.UUID.UniversalReference.source(m)
end

#=============================================
#
#=============================================
defimpl Noizu.EctoEntity.Protocol, for: [Map] do
  def universal_reference?(_), do: false
  def supported?(%{__struct__: module}) do
    try do
      module.ecto_entity?()
    rescue _e -> false
    catch _e -> false
    end
  end
  def supported?(_), do: false

  def ecto_identifier(%{__struct__: module} = m) do
    if supported?(m) do
      module.ecto_identifier(m)
    end
  end
  def ecto_identifier(_), do: nil

  def universal_identifier(%{__struct__: module} = m) do
    if supported?(m) do
      module.universal_identifier(m)
    end
  end
  def universal_identifier(_), do: nil


  def index_identifier(%{__struct__: module} = m) do
    if supported?(m) do
      module.index_identifier(m)
    end
  end
  def index_identifier(_), do: nil
  
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
