#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.DateTime do

  defmodule Millisecond.TypeHandler do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
    Noizu.DomainObject.noizu_sphinx_handler()

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


    #===------
    # dump
    #===------
    def dump(field, _segment, nil, _type, %{type: :ecto}, _context, _options), do: {field, nil}
    def dump(field, _segment, nil, _type, %{type: :mnesia}, _context, _options), do: {field, nil}
    def dump(field, _segment, v, _type, %{type: :ecto}, _context, _options), do: {field, %{v| microsecond: {0, 6}}}
    def dump(field, _segment, v, _type, %{type: :mnesia}, _context, _options), do: {field, DateTime.to_unix(v, :millisecond)}

    #===------
    # from_json
    #===------
    def from_json(_format, field, json, _context, _options) do
      case json[Atom.to_string(field)] do
        v when is_bitstring(v) ->
             case DateTime.from_iso8601(v) do
               {:ok, v} -> v
               _ -> nil
             end
        v when is_integer(v) -> DateTime.from_unix(v, :millisecond)
        _ -> nil
      end
    end

    #===------
    #
    #===------
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
                9999999999 -> 9999999998 # work around for nil handling
                nil -> 9999999999
                v when is_integer(v) -> v
                _ -> 9999999999
              end
      value
    end
  end

  defmodule Second.TypeHandler do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
    Noizu.DomainObject.noizu_sphinx_handler()


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

    def dump(field, _segment, nil, _type, %{type: :ecto}, _context, _options), do: {field, nil}
    def dump(field, _segment, nil, _type, %{type: :mnesia}, _context, _options), do: {field, nil}
    def dump(field, _segment, v, _type, %{type: :ecto}, _context, _options), do: {field, DateTime.truncate(v, :second)}
    def dump(field, _segment, v, _type, %{type: :mnesia}, _context, _options), do: {field, DateTime.to_unix(v, :second)}

    #===------
    # from_json
    #===------
    def from_json(_format, field, json, _context, _options) do
      case json[Atom.to_string(field)] do
        v when is_bitstring(v) ->
          case DateTime.from_iso8601(v) do
            {:ok, v} -> v
            _ -> nil
          end
        v when is_integer(v) -> DateTime.from_unix(v, :second)
        _ -> nil
      end
    end

    #def __strip_inspect__(field, value, _opts), do: {field, value && DateTime.to_iso8601(value)}

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
                9999999999 -> 9999999998 # work around for nil handling
                nil -> 9999999999
                v when is_integer(v) -> v
                _ -> 9999999999
              end
      value
    end
  end
end
