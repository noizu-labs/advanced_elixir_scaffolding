#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V3.Millisecond.TimeStamp do
  use Noizu.SimpleObject
  @vsn 1.0
  date_time_handler = Application.get_env(:noizu_scaffolding, :usec_data_time_handler, Noizu.Scaffolding.V3.DateTime.Millisecond.PersistenceStrategy)
  Noizu.SimpleObject.noizu_struct() do
    public_field :created_on, nil, date_time_handler
    public_field :modified_on, nil, date_time_handler
    public_field :deleted_on, nil, date_time_handler
  end

  #---------------------------------------------------------------
  # Methods
  #---------------------------------------------------------------
  def new(new, _options \\ nil) do
    #new = options[:current_time] || DateTime.utc_now()
    %__MODULE__{
      created_on: new,
      modified_on: new,
      deleted_on: nil,
    }
  end
  def now(options \\ nil) do
    now = options[:current_time] || DateTime.utc_now()
    %__MODULE__{
      created_on: now,
      modified_on: now,
      deleted_on: nil,
    }
  end


  def import(created_on, modified_on, deleted_on, type \\ :microsecond)
  def import(created_on, modified_on, deleted_on, type) do
    %__MODULE__{
      created_on: @date_time_handler.import(created_on, type),
      modified_on: @date_time_handler.import(modified_on, type),
      deleted_on: @date_time_handler.import(deleted_on, type),
    }
  end


  def compare(a, b, options \\ nil)
  def compare(a = %__MODULE__{}, b = %__MODULE__{}, options) do
    cond do
      a.created_on != b.created_on -> :neq
      a.modified_on != b.modified_on -> :neq
      a.deleted_on != b.deleted_on -> :neq
      :else -> :eq
    end
  end
  def compare(%__MODULE__{}, nil, _options), do: :neq
  def compare(nil, %__MODULE__{}, _options), do: :neq
  def compare(nil, nil, _options), do: :eq

  #===============================================================
  # Noizu.Scaffolding.V3.MilliSecond.TimeStamp.Type
  #===============================================================
  defmodule PersistenceStrategy do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()

    #----------------------------------
    # pre_create_callback
    #----------------------------------
    def pre_create_callback(field, entity, _context, options) do
      update_in(entity, [Access.key(field)], fn
        (v = %Noizu.Scaffolding.V3.Millisecond.TimeStamp{}) -> v
        (v = %DateTime{}) -> %Noizu.Scaffolding.V3.Millisecond.TimeStamp{created_on: v, modified_on: v, deleted_on: nil}
        (_) ->
          now = options[:current_time] || DateTime.utc_now()
          %Noizu.Scaffolding.V3.Millisecond.TimeStamp{created_on: now, modified_on: now, deleted_on: nil}
      end)
    end
    def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

    #----------------------------------
    # cast
    #----------------------------------
    def cast(:time_stamp, _segment, nil, _type, _layer, _context, _options), do: [{:created_on, nil}, {:modified_on, nil}, {:deleted_on, nil}]
    def cast(:time_stamp, _segment, v = %Noizu.Scaffolding.V3.Millisecond.TimeStamp{}, _type, %{type: :ecto}, _context, _options) do
      [
        {:created_on, v.created_on && %{v.created_on| microsecond: {0, 6}}},
        {:modified_on, v.modified_on && %{v.modified_on| microsecond: {0, 6}}},
        {:deleted_on, v.deleted_on && %{v.deleted_on| microsecond: {0, 6}}},
      ]
    end
    def cast(:time_stamp, _segment, v = %Noizu.Scaffolding.V3.Millisecond.TimeStamp{}, _type, %{type: :mnesia}, _context, _options) do
      [
        {:created_on, v.created_on && DateTime.to_unix(v.created_on, :millisecond)},
        {:modified_on, v.modified_on && DateTime.to_unix(v.modified_on, :millisecond)},
        {:deleted_on, v.deleted_on && DateTime.to_unix(v.deleted_on, :millisecond)}
      ]
    end

    #----------------------------------
    # dump
    #----------------------------------
    def dump(:time_stamp, record, _type, %{type: :ecto}, _context, _options) do
      {:time_stamp,
        %Noizu.Scaffolding.V3.Millisecond.TimeStamp{
          created_on: record && record.created_on,
          modified_on: record && record.modified_on,
          deleted_on: record && record.deleted_on
        }
      }
    end
    def dump(field, record, type, layer, context, options), do: super(field, record, type, layer, context, options)




  end
end
