#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021  Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.UniversalReference do
  @vsn 1.0
  use Amnesia

  @type t :: %Noizu.AdvancedScaffolding.UniversalReference{
               identifier: integer, # ref or actual universal id.
               ref: nil | tuple | any,
               # ref or actual entity
             }

  defstruct [
    identifier: nil,
    ref: nil
  ]

  #---------------------------
  #
  #---------------------------
  def erp_handler(), do: __MODULE__

  #=============================================================================
  # Noizu.AdvancedScaffolding.EctoEntity.Protocol Methods
  #=============================================================================
  def mysql_entity?(), do: true
  def ecto_identifier(ref) do
    r = resolve(ref)
    Noizu.AdvancedScaffolding.EctoEntity.Protocol.ecto_identifier(r)
  end
  def source(ref) do
    r = resolve(ref)
    Noizu.AdvancedScaffolding.EctoEntity.Protocol.source(r)
  end

  #---------------------------
  #
  #---------------------------
  def universal_identifier(%__MODULE__{identifier: v}) when is_integer(v), do: v
  def universal_identifier(%{__struct__: __MODULE__} = this) do
    cond do
      v = (this.ref && Noizu.AdvancedScaffolding.EctoEntity.Protocol.universal_identifier(this.ref)) -> v
      v = (this.identifier && Noizu.AdvancedScaffolding.EctoEntity.Protocol.universal_identifier(this.identifier)) -> v
    end
  end
  def universal_identifier({:ref, __MODULE__, v}) when is_integer(v), do: v
  def universal_identifier({:ref, __MODULE__, ref}) do
    Noizu.AdvancedScaffolding.EctoEntity.Protocol.universal_identifier(ref)
  end
  def universal_identifier(nil), do: nil
  def universal_identifier(v), do: Noizu.AdvancedScaffolding.EctoEntity.Protocol.universal_identifier(v)

  #---------------------------
  #
  #---------------------------
  def encode(%{__struct__: __MODULE__} = this), do: this
  def encode({:ref, Noizu.AdvancedScaffolding.UniversalReference, id}), do: %__MODULE__{identifier: id}
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
    case Noizu.AdvancedScaffolding.Database.UniversalReverseLookupTable.read!(v) do
      %Noizu.AdvancedScaffolding.Database.UniversalReverseLookupTable{ref: ref} -> ref
      _ -> nil # TODO fallback to database.
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
    case Noizu.AdvancedScaffolding.Database.UniversalLookupTable.read!(ref) do
      %Noizu.AdvancedScaffolding.Database.UniversalLookupTable{universal_identifier: id} -> {:ref, __MODULE__, id}
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

  def entity!(%{__struct__: __MODULE__} = this) do
    Noizu.ERP.entity!(resolve(this))
  end
  def entity!(v) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> entity!(u)
    end
  end

  def entity(%{__struct__: __MODULE__} = this) do
    Noizu.ERP.entity(resolve(this))
  end
  def entity(v) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> entity(u)
    end
  end

  def record!(%{__struct__: __MODULE__} = this) do
    Noizu.ERP.record!(resolve(this))
  end
  def record!(v) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> record!(u)
    end
  end

  def record(%{__struct__: __MODULE__} = this) do
    Noizu.ERP.record(resolve(this))
  end
  def record(v) do
    case encode(v) do
      nil -> nil
      u = %{__struct__: __MODULE__} -> record(u)
    end
  end

end
