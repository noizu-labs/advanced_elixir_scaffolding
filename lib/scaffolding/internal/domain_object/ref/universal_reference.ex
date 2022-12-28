#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Universal do
  @moduledoc """
  Provides ECTO handler to convert between a DomainObject.Entity mysql identifier or uuid and elixir ref format for Entities that support Universal IDs.
  """

  defmodule IntegerDefault do
    def cast(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        {:ref, Noizu.DomainObject.Integer.UniversalReference, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        %{__struct__: Noizu.DomainObject.Integer.UniversalReference} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref({:ecto_identifier, e, v})
          ref && {:ok, ref} || :error
        _ -> :error
      end
    end

    def cast!(m, value) do
      case m.cast(value) do
        {:ok, v} -> v
        :error -> raise Ecto.CastError, type: m, value: value
      end
    end

    def dump(_m, v) do
      cond do
        v == nil -> {:ok, 0}
        v = Noizu.EctoEntity.Protocol.ecto_identifier(v) -> {:ok, v}
        :else -> {:ok, 0}
      end
    end

    def load(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        {:ref, Noizu.DomainObject.Integer.UniversalReference, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        %{__struct__: Noizu.DomainObject.Integer.UniversalReference} -> {:ok, v}
        v when is_integer(v) ->
          ref = e.ref({:ecto_identifier, e, v})
          ref && {:ok, ref} || raise ArgumentError, "Unsupported #{m} - #{inspect v}"
        _ -> raise ArgumentError, "Unsupported #{m} - #{inspect v}"
      end
    end

  end



  defmodule UUIDDefault do
    def cast(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        {:ref, Noizu.DomainObject.UUID.UniversalReference, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        %{__struct__: Noizu.DomainObject.UUID.UniversalReference} -> {:ok, v}
        <<v::binary-size(16)>> ->
          ref = e.ref({:uuid_identifier, e, v})
          ref && {:ok, ref} || :error
        v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> ->
          ref = e.ref({:uuid_identifier, e, UUID.string_to_binary!(v)})
          ref && {:ok, ref} || :error
        _ -> :error
      end
    end
  
    def cast!(m, value) do
      case m.cast(value) do
        {:ok, v} -> v
        :error -> raise Ecto.CastError, type: m, value: value
      end
    end
  
    def dump(_m, v) do
      cond do
        v == nil -> {:ok, nil}
        v = Noizu.EctoEntity.Protocol.universal_identifier(v) -> Ecto.UUID.dump(v)
        :else -> {:ok, nil}
      end
    end
  
    def load(m, v) do
      e = m.__entity__
      case v do
        true -> {:ok, nil}
        false -> {:ok, nil}
        nil -> {:ok, nil}
        0 -> {:ok, nil}
        {:ref, ^e, _id} -> {:ok, v}
        {:ref, Noizu.DomainObject.UUID.UniversalReference, _id} -> {:ok, v}
        %{__struct__: ^e} -> {:ok, v}
        %{__struct__: Noizu.DomainObject.UUID.UniversalReference} -> {:ok, v}
        <<v::binary-size(16)>> ->
          ref = e.ref({:uuid_identifier, e, v})
          ref && {:ok, ref} || :error
        v = <<_,_,_,_,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,?-,_,_,_,_,_,_,_,_,_,_,_,_>> ->
          ref = e.ref({:uuid_identifier, e, UUID.string_to_binary!(v)})
          ref && {:ok, ref} || raise ArgumentError, "Unsupported #{m} - #{inspect v}"
        _ -> raise ArgumentError, "Unsupported #{m} - #{inspect v}"
      end
    end
  end
  
  
  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    entity = options[:entity]
    ecto_type = options[:ecto_type]
    reference_type = options[:reference_type]

    quote bind_quoted: [
            caller_file: __CALLER__.file,
            caller_line: __CALLER__.line,
            options: options,
            entity: entity,
            reference_type: reference_type,
            ecto_type: ecto_type
          ] do
      @behaviour Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Behaviour

      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @reference_type (case reference_type do
                         nil -> Application.get_env(:noizu_advanced_scaffolding, :universal_reference_type, :integer)
                         v when is_atom(v) -> v
                       end)

      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @handler (case @reference_type do
                  :uuid -> Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Universal.UUIDDefault
                  :integer -> Noizu.AdvancedScaffolding.Internal.Ecto.Reference.Universal.IntegerDefault
                end)

      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @ecto_type (case ecto_type do
                    nil -> case @reference_type do
                             :uuid -> :uuid
                             :integer -> :integer
                           end
                    v -> v
                  end)

      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use Ecto.Type
      @ref_entity entity

      #----------------------------
      # type
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def type, do: @ecto_type

      #----------------------------
      # __entity__
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __entity__, do: @ref_entity

      #----------------------------
      # cast
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Casts to Ref.
      """
      def cast(v), do: @handler.cast(__MODULE__, v)

      #----------------------------
      # cast!
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
      """
      def cast!(v), do: @handler.cast!(__MODULE__, v)

      #----------------------------
      # dump
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc false
      def dump(v), do: @handler.dump(__MODULE__, v)

      #----------------------------
      # load
      #----------------------------
      @file caller_file <> ":#{caller_line}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def load(v), do: @handler.load(__MODULE__, v)
    end
  end

end
