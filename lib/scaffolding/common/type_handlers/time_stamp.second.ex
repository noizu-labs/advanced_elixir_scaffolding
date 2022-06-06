#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.TimeStamp.Second do
  use Noizu.SimpleObject
  @vsn 1.0
  @kind "__TimeStamp__"
  Noizu.SimpleObject.noizu_struct() do
    date_time_handler = Application.get_env(:noizu_advanced_scaffolding, :data_time_handler, Noizu.DomainObject.DateTime.Second.TypeHandler)
    @json {[:mobile, :verbose], :suppress_meta}
    public_field :created_on, nil, date_time_handler
    public_field :modified_on, nil, date_time_handler
    public_field :deleted_on, nil, date_time_handler
  end
  date_time_handler = Application.get_env(:noizu_advanced_scaffolding, :usec_data_time_handler, Noizu.DomainObject.DateTime.Second.TypeHandler)
  @date_time_handler date_time_handler
  #---------------------------------------------------------------
  # Methods
  #---------------------------------------------------------------
  def new(new, _options \\ nil) do
    new = new && DateTime.truncate(new, :second)
    %__MODULE__{
      created_on: new,
      modified_on: new,
      deleted_on: nil,
    }
  end
  def now(options \\ nil) do
    now = options[:current_time] || DateTime.utc_now()
    now = now && DateTime.truncate(now, :second)
    %__MODULE__{
      created_on: now,
      modified_on: now,
      deleted_on: nil,
    }
  end


  def import(created_on, modified_on, deleted_on, type \\ :microsecond)
  def import(created_on, modified_on, deleted_on, type) do
    created_on = @date_time_handler.import(created_on, type)
    created_on = created_on && DateTime.truncate(created_on, :second)
    modified_on = @date_time_handler.import(modified_on, type)
    modified_on = modified_on && DateTime.truncate(modified_on, :second)
    deleted_on = @date_time_handler.import(deleted_on, type)
    deleted_on = deleted_on && DateTime.truncate(deleted_on, :second)
    %__MODULE__{
      created_on: created_on,
      modified_on: modified_on,
      deleted_on: deleted_on,
    }
  end


  def compare(a, b, options \\ nil)
  def compare(a = %{__struct__: __MODULE__}, b = %{__struct__: __MODULE__}, _options) do
    cond do
      a.created_on != b.created_on -> :neq
      a.modified_on != b.modified_on -> :neq
      a.deleted_on != b.deleted_on -> :neq
      :else -> :eq
    end
  end
  def compare(%{__struct__: __MODULE__}, nil, _options), do: :neq
  def compare(nil, %{__struct__: __MODULE__}, _options), do: :neq
  def compare(nil, nil, _options), do: :eq


  #===============================================================
  # Noizu.DomainObject.TimeStamp.Second.Type
  #===============================================================
  defmodule TypeHandler do
    require  Noizu.DomainObject
    Noizu.DomainObject.noizu_type_handler()
    Noizu.DomainObject.noizu_sphinx_handler()

    def __strip_inspect__(field, value, _opts) do
      case value do
        %{__struct__: Noizu.DomainObject.TimeStamp.Second} -> {field, {value.created_on, value.modified_on, value.deleted_on}}
        %DateTime{} -> {field, {value, value, nil}}
        _ -> {field, :auto}
      end
    end

    #----------------------------------
    #
    #----------------------------------
    def pre_create_callback(field, entity, _context, options) do
      update_in(entity, [Access.key(field)], fn
        (v = %{__struct__: Noizu.DomainObject.TimeStamp.Second}) -> v
        (v = %DateTime{}) -> %Noizu.DomainObject.TimeStamp.Second{created_on: v, modified_on: v, deleted_on: nil}
        (_) ->
          now = options[:current_time] || DateTime.utc_now()
          %Noizu.DomainObject.TimeStamp.Second{created_on: now, modified_on: now, deleted_on: nil}
      end)
    end
    def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

    #----------------------------------
    # dump
    #----------------------------------
    def dump(:time_stamp, _segment, nil, _type, _layer, _context, _options), do: [{:created_on, nil}, {:modified_on, nil}, {:deleted_on, nil}]
    def dump(:time_stamp, _segment, v = %{__struct__: Noizu.DomainObject.TimeStamp.Second}, _type, %{type: :ecto}, _context, _options) do
      [
        {:created_on, v.created_on && DateTime.truncate(v.created_on, :second) || nil},
        {:modified_on, v.modified_on && DateTime.truncate(v.modified_on, :second) || nil},
        {:deleted_on, v.deleted_on && DateTime.truncate(v.deleted_on, :second) || nil},
      ]
    end
    def dump(:time_stamp, _segment, v = %{__struct__: Noizu.DomainObject.TimeStamp.Second}, _type, %{type: :mnesia}, _context, _options) do
      [
        {:created_on, v.created_on && DateTime.to_unix(v.created_on, :second) || nil},
        {:modified_on, v.modified_on && DateTime.to_unix(v.modified_on, :second) || nil},
        {:deleted_on, v.deleted_on && DateTime.to_unix(v.deleted_on, :second) || nil}
      ]
    end

    def dump(field, _segment, nil, _type, _layer, _context, _options), do: [{:"#{field}_created_on", nil}, {:"#{field}_modified_on", nil}, {:"#{field}_deleted_on", nil}]
    def dump(field, _segment, v = %{__struct__: Noizu.DomainObject.TimeStamp.Second}, _type, %{type: :ecto}, _context, _options) do
      [
        {:"#{field}_created_on", v.created_on && DateTime.truncate(v.created_on, :second) || nil},
        {:"#{field}_modified_on", v.modified_on && DateTime.truncate(v.modified_on, :second) || nil},
        {:"#{field}_deleted_on", v.deleted_on && DateTime.truncate(v.deleted_on, :second) || nil},
      ]
    end
    def dump(field, _segment, v = %{__struct__: Noizu.DomainObject.TimeStamp.Second}, _type, %{type: :mnesia}, _context, _options) do
      [
        {:"#{field}_created_on", v.created_on && DateTime.to_unix(v.created_on, :second) || nil},
        {:"#{field}_modified_on", v.modified_on && DateTime.to_unix(v.modified_on, :second) || nil},
        {:"#{field}_deleted_on", v.deleted_on && DateTime.to_unix(v.deleted_on, :second) || nil}
      ]
    end
    def dump(field, segment, value, type, layer, context, options), do: super(field, segment, value, type, layer, context, options)



    #----------------------------------
    # cast
    #----------------------------------
    def cast(:time_stamp, record, _type, %{type: :ecto}, _context, _options) do
      {:time_stamp,
        %Noizu.DomainObject.TimeStamp.Second{
          created_on: record && record.created_on,
          modified_on: record && record.modified_on,
          deleted_on: record && record.deleted_on
        }
      }
    end
    def cast(field, record, _type, %{type: :ecto}, _context, _options) do
      {field,
        %Noizu.DomainObject.TimeStamp.Second{
          created_on: record && Map.get(record, :"#{field}_created_on"),
          modified_on: record && Map.get(record, :"#{field}_modified_on"),
          deleted_on: record && Map.get(record, :"#{field}_deleted_on"),
        }
      }
    end
    def cast(field, record, type, layer, context, options), do: super(field, record, type, layer, context, options)

    #===------
    # from_json
    #===------
    def from_json(format, field, json, context, options) do
      case json[Atom.to_string(field)] do
        v when is_map(v) ->
          %Noizu.DomainObject.TimeStamp.Second{
            created_on:  Noizu.DomainObject.DateTime.Second.TypeHandler.from_json(format, :created_on, v, context, options),
            modified_on:  Noizu.DomainObject.DateTime.Second.TypeHandler.from_json(format, :modified_on, v, context, options),
            deleted_on:  Noizu.DomainObject.DateTime.Second.TypeHandler.from_json(format, :deleted_on, v, context, options),
          }
        _ -> nil
      end
    end

    #===============================================
    # Sphinx Handler
    #===============================================


    #===------
    #
    #===------
    def __search_clauses__(index, {field, settings}, conn, params, context, options) do
      date_time_handler = Application.get_env(:noizu_advanced_scaffolding, :usec_data_time_handler, Noizu.DomainObject.DateTime.Second.TypeHandler)
      search = case field do
                 {p, f} -> "#{p}.#{f}"
                 _ -> "#{field}"
               end
      [
        date_time_handler.__search_clauses__(index, {{search, :created_on}, settings}, conn, params, context, options),
        date_time_handler.__search_clauses__(index, {{search, :modified_on}, settings}, conn, params, context, options),
        date_time_handler.__search_clauses__(index, {{search, :deleted_on}, settings}, conn, params, context, options),
        Noizu.AdvancedScaffolding.Sphinx.Type.Bool.__search_clauses__(index, {{search, :deleted}, settings}, conn, params, context, options),
      ] |> Enum.filter(&(&1))
    end

    def __sphinx_field__(), do: true
    def __sphinx_expand_field__(field, indexing, _settings) do
      indexing = update_in(indexing, [:from], &(&1 || field))
      [
        {:"#{field}_created_on", __MODULE__, put_in(indexing, [:sub], :created_on)}, #rather than __MODULE__ here we could use Sphinx providers like Sphinx.NullableInteger
        {:"#{field}_modified_on", __MODULE__, put_in(indexing, [:sub], :modified_on)},
        {:"#{field}_deleted_on", __MODULE__, put_in(indexing, [:sub], :deleted_on)},
        {:"#{field}_deleted", __MODULE__, put_in(indexing, [:sub], :deleted)},
      ]
    end
    def __sphinx_has_default__(_field, _indexing, _settings), do: true
    def __sphinx_default__(_field, _indexing, _settings) do
      :none
    end
    def __sphinx_encoding__(_field, indexing, _settings) do
      cond do
        indexing[:sub] == :created_on -> :attr_timestamp
        indexing[:sub] == :modified_on -> :attr_timestamp
        indexing[:sub] == :deleted_on -> :attr_timestamp
        indexing[:sub] == :deleted -> :attr_uint
      end
    end
    def __sphinx_encoded__(_field, entity, indexing, _settings) do
      value = get_in(entity, [Access.key(indexing[:from])])
      cond do
        indexing[:sub] == :created_on -> value && value.created_on && DateTime.to_unix(value.created_on) || 9999999999
        indexing[:sub] == :modified_on -> value && value.modified_on && DateTime.to_unix(value.modified_on) || 9999999999
        indexing[:sub] == :deleted_on -> value && value.deleted_on && DateTime.to_unix(value.deleted_on) || 9999999999
        indexing[:sub] == :deleted -> value && value.deleted_on && 1 || 0
      end
    end



  end

end
