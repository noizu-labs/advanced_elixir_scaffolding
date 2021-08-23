#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Scaffolding.V3.TimeStamp do
  use Noizu.SimpleObject
  @vsn 1.0
  Noizu.SimpleObject.noizu_struct() do
    date_time_handler = Application.get_env(:noizu_scaffolding, :data_time_handler, Noizu.Scaffolding.V3.DateTime.Second.PersistenceStrategy)
    public_field :created_on, nil, date_time_handler
    public_field :modified_on, nil, date_time_handler
    public_field :deleted_on, nil, date_time_handler
  end
  date_time_handler = Application.get_env(:noizu_scaffolding, :usec_data_time_handler, Noizu.Scaffolding.V3.DateTime.Second.PersistenceStrategy)
  @date_time_handler date_time_handler
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
  def compare(a = %__MODULE__{}, b = %__MODULE__{}, _options) do
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
  # Noizu.Scaffolding.V3.TimeStamp.Type
  #===============================================================
  defmodule PersistenceStrategy do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
    Noizu.DomainObject.noizu_sphinx_handler()

    def strip_inspect(field, value, _opts) do
      case value do
        %Noizu.Scaffolding.V3.TimeStamp{} -> {field, {value.created_on, value.modified_on, value.deleted_on}}
        %DateTime{} -> {field, {value, value, nil}}
        _ -> {field, :auto}
      end
    end

    #----------------------------------
    #
    #----------------------------------
    def pre_create_callback(field, entity, _context, options) do
      update_in(entity, [Access.key(field)], fn
          (v = %Noizu.Scaffolding.V3.TimeStamp{}) -> v
          (v = %DateTime{}) -> %Noizu.Scaffolding.V3.TimeStamp{created_on: v, modified_on: v, deleted_on: nil}
          (_) ->
            now = options[:current_time] || DateTime.utc_now()
            %Noizu.Scaffolding.V3.TimeStamp{created_on: now, modified_on: now, deleted_on: nil}
        end)
    end
    def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

    #----------------------------------
    #
    #----------------------------------
    def cast(:time_stamp, _segment, nil, _type, _layer, _context, _options), do: [{:created_on, nil}, {:modified_on, nil}, {:deleted_on, nil}]
    def cast(:time_stamp, _segment, v = %Noizu.Scaffolding.V3.TimeStamp{}, _type, %{type: :ecto}, _context, _options) do
      [
        {:created_on, v.created_on && DateTime.truncate(v.created_on, :second)},
        {:modified_on, v.modified_on && DateTime.truncate(v.modified_on, :second)},
        {:deleted_on, v.deleted_on && DateTime.truncate(v.deleted_on, :second)},
      ]
    end
    def cast(:time_stamp, _segment, v = %Noizu.Scaffolding.V3.TimeStamp{}, _type, %{type: :mnesia}, _context, _options) do
      [
        {:created_on, v.created_on && DateTime.to_unix(v.created_on, :second)},
        {:modified_on, v.modified_on && DateTime.to_unix(v.modified_on, :second)},
        {:deleted_on, v.deleted_on && DateTime.to_unix(v.deleted_on, :second)}
      ]
    end

    #----------------------------------
    # dump
    #----------------------------------
    def dump(:time_stamp, record, _type, %{type: :ecto}, _context, _options) do
      {:time_stamp,
        %Noizu.Scaffolding.V3.TimeStamp{
          created_on: record && record.created_on,
          modified_on: record && record.modified_on,
          deleted_on: record && record.deleted_on
        }
      }
    end
    def dump(field, record, type, layer, context, options), do: super(field, record, type, layer, context, options)



    #===============================================
    # Sphinx Handler
    #===============================================
    def __sphinx_field__(), do: true
    def __sphinx_expand_field__(field, indexing, _settings) do
      indexing = update_in(indexing, [:from], &(&1 || field))
      [
        {:"#{field}_created_on", __MODULE__, put_in(indexing, [:sub], :created_on)}, #rather than __MODULE__ here we could use Sphinx providers like Sphinx.NullableInteger
        {:"#{field}_modified_on", __MODULE__, put_in(indexing, [:sub], :modified_on)},
        {:"#{field}_deleted", __MODULE__, put_in(indexing, [:sub], :deleted)},
      ]
    end
    def __sphinx_has_default__(_field, _indexing, _settings), do: true
    def __sphinx_default__(_field, indexing, _settings) do
      :none
    end
    def __sphinx_encoding__(field, indexing, settings) do
      cond do
        indexing[:sub] == :created_on -> :attr_timestamp
        indexing[:sub] == :modified_on -> :attr_timestamp
        indexing[:sub] == :deleted -> :attr_uint
      end
    end
    def __sphinx_encoded__(field, entity, indexing, settings) do
      value = get_in(entity, [Access.key(indexing[:from])])
      cond do
        indexing[:sub] == :created_on -> value && value.created_on && DateTime.to_unix(value.created_on) || 9999999999
        indexing[:sub] == :modified_on -> value && value.modified_on && DateTime.to_unix(value.modified_on) || 9999999999
        indexing[:sub] == :deleted -> value && value.deleted_on && 1 || 0
      end
    end



  end

end
