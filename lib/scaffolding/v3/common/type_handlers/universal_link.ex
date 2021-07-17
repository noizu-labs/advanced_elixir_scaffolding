#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.UniversalLink do

  defmodule PersistenceStrategy do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()

    #--------------------------------------
    #
    #--------------------------------------
    def pre_create_callback(_field, entity, _context, _options), do: entity
    def pre_create_callback!(_field, entity, _context, _options), do: entity

    #--------------------------------------
    #
    #--------------------------------------
    def cast(field, _segment, v, _type, %{type: :ecto}, _context, _options) do
      case Noizu.ERP.ref(v) do
        {:ref, m, identifier} ->
          [
            {:"#{field}_type", m.__persistence__().ecto_entity},
            {:"#{field}_identifier", identifier},
          ]
        _ ->
          [
            {:"#{field}_type", nil},
            {:"#{field}_identifier", nil},
          ]
      end
    end
    def cast(field, _segment, v, _type, %{ecto: :mnesia}, _context, _options) do
      [
        {field, Noizu.ERP.ref(v)}
      ]
    end
    def cast(field, _segment, v, _type, _, _context, _options) do
      [
        {field, Noizu.ERP.ref(v)}
      ]
    end

    #--------------------------------------
    #
    #--------------------------------------
    def dump(field, record, _type, %{type: :ecto}, _context, _options) do
      source_field = "#{field}_source"
      id_field = "#{field}_identifier"
      source = get_in(record, [Access.key(source_field)])
      identifier = get_in(record, [Access.key(id_field)])
      ref = source && source.__entity__.ref(identifier)
      [{field, ref}]
    end
    def dump(field, record, type, layer, context, options), do: super(field, record, type, layer, context, options)

  end
end