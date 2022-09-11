#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021  Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.Integer.UniversalReference do
  @vsn 1.0
  use Amnesia

  @type t :: %Noizu.DomainObject.Integer.UniversalReference{
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
  def universal_identifier(%{__struct__: __MODULE__, identifier: v}) when is_integer(v), do: v
  def universal_identifier(%{__struct__: __MODULE__} = this) do
    cond do
      v = (this.ref && Noizu.EctoEntity.Protocol.universal_identifier(this.ref)) -> v
      v = (this.identifier && Noizu.EctoEntity.Protocol.universal_identifier(this.identifier)) -> v
      :else -> nil
    end
  end
  def universal_identifier({:ref, __MODULE__, v}) when is_integer(v), do: v
  def universal_identifier({:ref, __MODULE__, ref}) do
    Noizu.EctoEntity.Protocol.universal_identifier(ref)
  end
  def universal_identifier(nil), do: nil
  def universal_identifier(v), do: Noizu.EctoEntity.Protocol.universal_identifier(v)

  #---------------------------
  #
  #---------------------------
  def encode(%{__struct__: __MODULE__} = this), do: this
  def encode({:ref, Noizu.DomainObject.Integer.UniversalReference, id}), do: %__MODULE__{identifier: id}
  def encode({:ref, _m, _id} = ref), do: %__MODULE__{identifier: ref, ref: ref}
  def encode("ref.universal." <> id) do
    case Integer.parse(id) do
      {v, ""} -> encode(v)
      _ -> nil
    end
  end
  def encode("ref." <> _ = sref) do
    case Noizu.ERP.ref(sref) do
      nil -> nil
      ref -> %__MODULE__{identifier: ref, ref: ref}
    end
  end
  def encode(rrid) when is_integer(rrid) do
    %__MODULE__{identifier: rrid}
  end
  def encode(v = %{ecto_identifier: uid}) when is_integer(uid)  do
    %__MODULE__{identifier: uid, ref: v}
  end
  def encode(v = %{identifier: uid}) when is_integer(uid)  do
    %__MODULE__{identifier: uid, ref: v}
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
  def resolve(v) when is_integer(v) do
    case Noizu.DomainObject.UniversalLookup.reverse_lookup(v) do
      {:ok, ref} -> ref
      _ -> nil
    end
  end
  def resolve({:ref, __MODULE__, id}), do: resolve(id)
  def resolve("ref.universal." <> id) do
    case Integer.parse(id) do
      {v, ""} -> resolve(v)
      _ -> nil
    end
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
  def id(v) when is_integer(v), do: v
  def id({:ref, __MODULE__, identifier}), do: identifier
  def id("ref.universal." <> v) do
    case Integer.parse(v) do
      {identifier, ""} -> identifier
      _ -> nil
    end
  end
  def id(%{__struct__: __MODULE__} = this) do
    this.identifier
  end

  def ref(v) when is_integer(v), do: {:ref, __MODULE__, v}
  def ref({:ref, __MODULE__, _identifier} = ref), do: ref
  def ref("ref.universal." <> v) do
    case Integer.parse(v) do
      {identifier, ""} -> {:ref, __MODULE__, identifier}
      _ -> nil
    end
  end
  def ref(%{__struct__: __MODULE__} = this) do
    {:ref, __MODULE__, universal_identifier(this)}
  end



  def sref(v) when is_integer(v), do: "ref.universal.#{v}"
  def sref({:ref, __MODULE__, _id} = ref) do
    case universal_identifier(ref) do
      v when is_integer(v) -> "ref.universal.#{v}"
      _ -> nil
    end
  end
  def sref(%{__struct__: __MODULE__} = this) do
    case universal_identifier(this) do
      v when is_integer(v) -> "ref.universal.#{v}"
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
