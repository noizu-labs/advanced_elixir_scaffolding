#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.DateTime do

  defmodule Millisecond.PersistenceStrategy do
    @behaviour Noizu.Scaffolding.V3.SphinxFieldBehaviour
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()


    def import(value, type \\ :microsecond)
    def import(value, :microsecond), do: value && DateTime.from_unix!(DateTime.to_unix(value, :microsecond), :microsecond)


    def pre_create_callback(_field, entity, _context, _options) do
      entity
    end
    def pre_update_callback(_field, entity, _context, _options) do
      entity
    end
    def post_delete_callback(_field, entity, _context, _options) do
      entity
    end
    def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

    def cast(field, _segment, nil, _type, %{type: :ecto}, _context, _options), do: {field, nil}
    def cast(field, _segment, nil, _type, %{type: :mnesia}, _context, _options), do: {field, nil}
    def cast(field, _segment, v, _type, %{type: :ecto}, _context, _options), do: {field, %{v| microsecond: {0, 6}}}
    def cast(field, _segment, v, _type, %{type: :mnesia}, _context, _options), do: {field, DateTime.to_unix(v, :millisecond)}




    def __sphinx_field__(), do: true
    def __sphinx_expand_field__(field, indexing, _settings), do: {field, __MODULE__, indexing}
    def __sphinx_has_default__(_field, _indexing, _settings), do: false
    def __sphinx_default__(_field, _indexing, _settings), do: nil
    def __sphinx_bits__(_field, _indexing, _settings), do: nil
    def __sphinx_encoding__(_field, _indexing, _settings), do: :attr_timestamp
    def __sphinx_encoded__(field, entity, indexing, _settings) do
      source = cond do
                 s = indexing[:from] -> [Access.key(s)]
                 :else -> [Access.key(field)]
               end
      value = get_in(entity, source)
      value = case value do
                %DateTime{} -> DateTime.to_unix(value)
                _ -> nil
              end
      value = case value do
                31337 -> 31336 # work around for nil handling
                nil -> 31337
                v when is_integer(v) -> v
                _ -> 31337
              end
      value
    end
  end

  defmodule Second.PersistenceStrategy do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()


    def import(value, type \\ :microsecond)
    def import(value, :microsecond), do: value && DateTime.from_unix!(DateTime.to_unix(value, :microsecond), :microsecond)


    def pre_create_callback(_field, entity, _context, _options) do
      entity
    end
    def pre_update_callback(_field, entity, _context, _options) do
      entity
    end
    def post_delete_callback(_field, entity, _context, _options) do
      entity
    end
    def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

    def cast(field, _segment, nil, _type, %{type: :ecto}, _context, _options), do: {field, nil}
    def cast(field, _segment, nil, _type, %{type: :mnesia}, _context, _options), do: {field, nil}
    def cast(field, _segment, v, _type, %{type: :ecto}, _context, _options), do: {field, DateTime.truncate(v, :second)}
    def cast(field, _segment, v, _type, %{type: :mnesia}, _context, _options), do: {field, DateTime.to_unix(v, :second)}



    #def strip_inspect(field, value, _opts), do: {field, value && DateTime.to_iso8601(value)}

    def __sphinx_field__(), do: true
    def __sphinx_expand_field__(field, indexing, _settings), do: {field, __MODULE__, indexing}
    def __sphinx_has_default__(_field, _indexing, _settings), do: false
    def __sphinx_default__(_field, _indexing, _settings), do: nil
    def __sphinx_bits__(_field, _indexing, _settings), do: nil
    def __sphinx_encoding__(_field, _indexing, _settings), do: :attr_timestamp
    def __sphinx_encoded__(field, entity, indexing, _settings) do
      source = cond do
                 s = indexing[:from] -> [Access.key(s)]
                 :else -> [Access.key(field)]
               end
      value = get_in(entity, source)
      value = case value do
                %DateTime{} -> DateTime.to_unix(value)
                _ -> nil
              end
      value = case value do
                31337 -> 31336 # work around for nil handling
                nil -> 31337
                v when is_integer(v) -> v
                _ -> 31337
              end
      value
    end
  end
end
