#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UUID.UniversalLink do

  defmodule TypeHandler do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
    Noizu.DomainObject.noizu_sphinx_handler()
    @universal_lookup Application.get_env(:noizu_advanced_scaffolding, :universal_lookup, Noizu.DomainObject.UniversalLookup)

    #--------------------------------------
    #
    #--------------------------------------
    def pre_create_callback(_field, entity, _context, _options), do: entity
    def pre_create_callback!(_field, entity, _context, _options), do: entity

    #--------------------------------------
    # cast
    #--------------------------------------
    def dump(field, _segment, v, _type, %{type: :ecto}, _context, _options) do
      case Noizu.ERP.ref(v) do
        {:ref, m, identifier} ->
          [
            {:"#{field}_type", m.__persistence__().ecto_entity},
            {:"#{field}_identifier", Noizu.EctoEntity.Protocol.universal_identifier(v)},
            {field, {:ref, m, identifier}}
          ]
        _ ->
          [
            {:"#{field}_type", nil},
            {:"#{field}_identifier", nil},
            {field, nil}
          ]
      end
    end
    def dump(field, _segment, v, _type, %{ecto: :mnesia}, _context, _options) do
      [
        {field, Noizu.ERP.ref(v)}
      ]
    end
    def dump(field, _segment, v, _type, _, _context, _options) do
      [
        {field, Noizu.ERP.ref(v)}
      ]
    end

    #--------------------------------------
    # cast
    #--------------------------------------
    def cast(field, record, _type, %{type: :ecto}, _context, _options) do
      id_field = "#{field}_identifier"
      identifier = get_in(record, [Access.key(id_field)])
      ref = case @universal_lookup.lookup(identifier) do
              {:ok, v} -> v
              _ -> nil
            end
      [{field, ref}]
    end
    def cast(field, record, type, layer, context, options), do: super(field, record, type, layer, context, options)


    #===------
    # from_json
    #===------
    def from_json(_format, field, json, _context, _options) do
      case json[Atom.to_string(field)] do
        v when is_bitstring(v) ->
          Noizu.ERP.ref(v)
        v when is_map(v) ->
          IO.puts "if a map, check for kind field and if found use a generic json to entity method"
          nil
        _ -> nil
      end
    end


    #===============================================
    # Sphinx Handler
    #===============================================

    def __sphinx_field__(), do: true
    def __sphinx_expand_field__(field, indexing, _settings) do
      indexing = update_in(indexing, [:from], &(&1 || field))
      [
        {:"#{field}_uid", __MODULE__, put_in(indexing, [:sub], :identifier)}, #rather than __MODULE__ here we could use Sphinx providers like Sphinx.NullableInteger
        {:"#{field}_type", __MODULE__, put_in(indexing, [:sub], :type)},
      ]
    end
    def __sphinx_bits__(_field, _indexing, _settings), do: :auto
    def __sphinx_encoding__(_field, indexing, _settings) do
      cond do
        indexing[:sub] == :identifier -> :attr_bigint
        indexing[:sub] == :type -> :attr_uint
      end
    end
    def __sphinx_encoded__(_field, entity, indexing, _settings) do
      value = get_in(entity, [Access.key(indexing[:from])])
              |> Noizu.ERP.entity!()
      cond do
        !value ->
          cond do
            indexing[:sub] == :identifier -> nil
            indexing[:sub] == :type -> nil
          end
        indexing[:sub] == :identifier -> Noizu.EctoEntity.Protocol.index_identifier(value)
        indexing[:sub] == :type -> value.__struct__.__nmid__(:index)
      end
    end
  end
end
