#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021  Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UUID.UniversalReference do
  @vsn 1.0
  use Amnesia

  @type t :: %Noizu.DomainObject.UUID.UniversalReference{
               identifier: integer, # ref or actual universal id.
               ref: nil | tuple | any,
               # ref or actual entity
             }

  defstruct [
    identifier: nil,
    ref: nil
  ]

  @universal_lookup Application.get_env(:noizu_advanced_scaffolding, :universal_lookup, Noizu.DomainObject.UniversalLookup)
  
  #---------------------------
  #
  #---------------------------
  def erp_handler(), do: __MODULE__

  #=============================================================================
  # Noizu.EctoEntity.Protocol Methods
  #=============================================================================
  def mysql_entity?(), do: true
  def ecto_identifier(ref) do
    r = resolve(ref)
    Noizu.EctoEntity.Protocol.ecto_identifier(r)
  end
  def source(ref) do
    r = resolve(ref)
    Noizu.EctoEntity.Protocol.source(r)
  end

  #---------------------------
  #
  #---------------------------
  
  def universal_identifier(%{__struct__: __MODULE__, identifier: <<v::binary-size(16)>>
  }), do: UUID.binary_to_string!(v)
  def universal_identifier(%{__struct__: __MODULE__,
    identifier: <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>
  } = v), do: v.identifier
  def universal_identifier(%{__struct__: __MODULE__} = this) do
    cond do
      v = (this.ref && Noizu.EctoEntity.Protocol.universal_identifier(this.ref)) -> v
      v = (this.identifier && Noizu.EctoEntity.Protocol.universal_identifier(this.identifier)) -> v
      :else -> nil
    end
  end
  
  def universal_identifier({:ref, __MODULE__, <<v::binary-size(16)>>}), do: UUID.binary_to_string!(v)
  def universal_identifier({:ref, __MODULE__, <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = v}), do: v
  def universal_identifier({:ref, __MODULE__, ref}) do
    Noizu.EctoEntity.Protocol.universal_identifier(ref)
  end
  def universal_identifier(nil), do: nil
  def universal_identifier(v), do: Noizu.EctoEntity.Protocol.universal_identifier(v)

  def index_identifier(v) do
    r = resolve(v)
    r && Noizu.EctoEntity.Protocol.index_identifier(r)
  end
  
  #---------------------------
  #
  #---------------------------
  def encode(%{__struct__: __MODULE__} = this), do: this
  def encode({:ref, Noizu.DomainObject.UUID.UniversalReference, id}), do: %__MODULE__{identifier: id}
  def encode({:ref, _m, _id} = ref), do: %__MODULE__{identifier: ref, ref: ref}
  def encode("ref.universal." <> <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>) do
    encode(<<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>)
  end
  def encode("ref." <> _ = sref) do
    case Noizu.ERP.ref(sref) do
      nil -> nil
      ref -> %__MODULE__{identifier: ref, ref: ref}
    end
  end
  
  def encode(<<v::binary-size(16)>>) do
    #%__MODULE__{identifier: v}
    %__MODULE__{identifier: UUID.binary_to_string!(v)}
  end
  def encode(<<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = v) do
    #%__MODULE__{identifier: UUID.string_to_binary!(v)}
    %__MODULE__{identifier: v}
  end
  def encode(v = %{identifier: _, __struct__: _m}) do
    cond do
      ref = Noizu.ERP.ref(v) -> %__MODULE__{identifier: ref, ref: v}
      true -> nil
    end
  end
  def encode(_) do
    nil
  end

  #---------------------------
  #
  #---------------------------
  def resolve(%{__struct__: __MODULE__} = this) do
    cond do
      this.ref -> this.ref
      true -> resolve(this.identifier)
    end
  end

  

  def resolve(<<v::binary-size(16)>>) do
    case @universal_lookup.reverse_lookup(UUID.binary_to_string!(v)) do
      {:ok, ref} -> ref
      _ -> nil
    end
  end
  def resolve(v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>>) do
    case @universal_lookup.reverse_lookup(v) do
      {:ok, ref} -> ref
      _ -> nil
    end
  end
  def resolve({:ref, __MODULE__, id}), do: resolve(id)
  def resolve("ref.universal." <> <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>) do
    resolve(<<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>)
  end
  def resolve(v) do
    Noizu.ERP.ref(v)
  end

  #---------------------------
  #
  #---------------------------
  def lookup({:ref, _, _id} = ref) do
    case @universal_lookup.lookup(ref) do
      {:ok, id} -> {:ref, __MODULE__, id}
      _ -> nil
    end
  end

  #---------------------------
  #
  #---------------------------
  def id(<<v::binary-size(16)>>), do: UUID.binary_to_string!(v)
  def id(<<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = v), do: v
  def id({:ref, __MODULE__, identifier}), do: identifier
  def id("ref.universal." <> <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>) do
    #UUID.string_to_binary!(<<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>)
    <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>
  end
  def id(%{__struct__: __MODULE__} = this) do
    this.identifier
  end

  def ref(<<v::binary-size(16)>>), do: {:ref, __MODULE__, UUID.binary_to_string!(v)}
  def ref(<<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = v), do: {:ref, __MODULE__, v}
  def ref({:ref, __MODULE__, _identifier} = ref), do: ref
  def ref("ref.universal." <> <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>) do
    #{:ref, __MODULE__, UUID.string_to_binary!(<<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>)}
    {:ref, __MODULE__, <<a1,a2,a3,a4,a5,a6,a7,a8,?-,b1,b2,b3,b4,?-,c1,c2,c3,c4,?-,d1,d2,d3,d4,?-,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12>>}
  end
  def ref(%{__struct__: __MODULE__} = this) do
    {:ref, __MODULE__, universal_identifier(this)}
  end

  def sref(<<v::binary-size(16)>>), do: "ref.universal.#{UUID.binary_to_string!(v)}"
  def sref(<<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> = v), do: "ref.universal.#{v}"
  def sref({:ref, __MODULE__, _id} = ref) do
    case universal_identifier(ref) do
      <<v::binary-size(16)>> -> "ref.universal.#{UUID.binary_to_string!(v)}"
      v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> -> "ref.universal.#{v}"
      _ -> nil
    end
  end
  def sref(%{__struct__: __MODULE__} = this) do
    case universal_identifier(this) do
      <<v::binary-size(16)>> -> "ref.universal.#{UUID.binary_to_string!(v)}"
      v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> -> "ref.universal.#{v}"
      _ -> nil
    end
  end
  def sref(v) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> sref(u)
    end
  end

  def entity!(ref, options \\ [])
  def entity!(%{__struct__: __MODULE__} = this, options) do
    Noizu.ERP.entity!(resolve(this), options)
  end
  def entity!(v, _) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> entity!(u)
    end
  end

  def entity(ref, options \\ [])
  def entity(%{__struct__: __MODULE__} = this, options) do
    Noizu.ERP.entity(resolve(this), options)
  end
  def entity(v, options) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> entity(u, options)
    end
  end

  def record!(ref, options \\ [])
  def record!(%{__struct__: __MODULE__} = this, options) do
    Noizu.ERP.record!(resolve(this), options)
  end
  def record!(v, options) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> record!(u, options)
    end
  end

  def record(ref, options \\ [])
  def record(%{__struct__: __MODULE__} = this, options) do
    Noizu.ERP.record(resolve(this), options)
  end
  def record(v, options) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> record(u, options)
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


end
