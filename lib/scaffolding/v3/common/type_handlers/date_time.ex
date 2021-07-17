#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.DateTime do


  def import(value, type \\ :microsecond)
  def import(value, :microsecond), do: value && DateTime.from_unix!(DateTime.to_unix(value, :microsecond), :microsecond)

  defmodule Millisecond.PersistenceStrategy do
    @behaviour Noizu.Scaffolding.V3.SphinxFieldBehaviour
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
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
  end

  defmodule Second.PersistenceStrategy do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
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
  end
end
