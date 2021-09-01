defmodule Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Implementation.Default do
  alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer

  @moduledoc """
  Default Implementation.
  """


  #==========================================================
  # Persistence
  #==========================================================

  #-----------------------------------
  # __as_record__
  #-----------------------------------
  def __as_record__(domain_object, table, ref, context, options) when is_atom(table) do
    layer = domain_object.__persistence__(:table)[table]
    layer && domain_object.__as_record__(layer, ref, context, options)
  end
  def __as_record__(domain_object, layer = %PersistenceLayer{}, ref, context, options) do
    cond do
      entity = domain_object.entity(ref, options) -> __as_record_type__(domain_object, layer, entity, context, options)
      :else -> nil
    end
  end

  #-----------------------------------
  # __as_record__!
  #-----------------------------------
  def __as_record__!(domain_object, table, ref, context, options) when is_atom(table) do
    layer = domain_object.__persistence__(:table)[table]
    layer && domain_object.__as_record__!(layer, ref, context, options)
  end
  def __as_record__!(domain_object, layer = %PersistenceLayer{}, ref, context, options) do
    cond do
      entity = domain_object.entity(ref, options) -> __as_record_type__(domain_object, layer, entity, context, options)
      :else -> nil
    end
  end

  #-----------------------------------
  # __as_record_type__
  #-----------------------------------
  def __as_record_type__(domain_object, layer = %PersistenceLayer{type: :mnesia, table: table}, entity, context, options) do
    context = Noizu.ElixirCore.CallingContext.system(context)
    field_types = domain_object.__noizu_info__(:field_types)
    fields = Map.keys(table.__struct__([])) -- [:__struct__, :__transient__, :initial]
    Enum.map(
      fields,
      fn (field) ->
        cond do
          field == :identifier -> {field, entity.identifier}
          field == :entity -> {field, entity}
          entry = layer.schema_fields[field] ->
            type = field_types[entry[:source]]
            source = case entry[:selector] do
                       nil -> get_in(entity, [Access.key(entry[:source])])
                       path when is_list(path) -> get_in(entity, path)
                       {m, f, a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                       {m, f, a} -> apply(m, f, [entry, entity, a])
                       f when is_function(f, 0) -> f.()
                       f when is_function(f, 1) -> f.(entity)
                       f when is_function(f, 2) -> f.(entry, entity)
                       f when is_function(f, 3) -> f.(entry, entity, context)
                       f when is_function(f, 4) -> f.(entry, entity, context, options)
                     end
            type.handler.cast(entry[:source], entry[:segment], source, type, layer, context, options)
          Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
          :else -> nil
        end
      end
    )
    |> List.flatten()
    |> Enum.filter(&(&1))
    |> layer.table.__struct__()
  end

  def __as_record_type__(domain_object, layer = %{type: :ecto, table: table}, entity, _context, options) do
    context = Noizu.ElixirCore.CallingContext.admin()
    field_types = domain_object.__noizu_info__(:field_types)
    Enum.map(
      domain_object.__fields__(:persisted),
      fn (field) ->
        cond do
          field == :identifier -> {:identifier, Noizu.EctoEntity.Protocol.ecto_identifier(entity)}
          entry = layer.schema_fields[field] ->
            type = field_types[entry[:source]]
            source = case entry[:selector] do
                       nil -> get_in(entity, [Access.key(entry[:source])])
                       path when is_list(path) -> get_in(entity, path)
                       {m, f, a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                       {m, f, a} -> apply(m, f, [entry, entity, a])
                       f when is_function(f, 0) -> f.()
                       f when is_function(f, 1) -> f.(entity)
                       f when is_function(f, 2) -> f.(entry, entity)
                       f when is_function(f, 3) -> f.(entry, entity, context)
                       f when is_function(f, 4) -> f.(entry, entity, context, options)
                     end
            type.handler.cast(entry[:source], entry[:segment], source, type, layer, context, options)
          Map.has_key?(entity, field) -> {field, get_in(entity, [Access.key(field)])}
          :else -> nil
        end
      end
    )
    |> List.flatten()
    |> Enum.filter(&(&1))
    |> table.__struct__()
  end

  def __as_record_type__(_domain_object, _layer, _entity, _context, _options), do: nil

  #-----------------------------------
  # __as_record_type__!
  #-----------------------------------
  def __as_record_type__!(domain_object, layer, entity, context, options), do: __as_record_type__(domain_object, layer, entity, context, options)


  #-----------------------------------
  #
  #-----------------------------------
  def __from_record__(_domain_object, _layer, %{entity: temp}, _context, _options) do
    temp
  end
  def __from_record__(_domain_object, _layer, _ref, _context, _options) do
    nil
  end

  def __from_record__!(_domain_object, _layer, %{entity: temp}, _context, _options) do
    temp
  end
  def __from_record__!(_domain_object, _layer, _ref, _context, _options) do
    nil
  end

  #-----------------------------------
  #
  #-----------------------------------
  def ecto_identifier(_, %{ecto_identifier: id}), do: id
  def ecto_identifier(_, %{identifier: id}) when is_integer(id), do: id
  def ecto_identifier(m, ref) do
    ref = m.ref(ref)
    case Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table.read!(ref) do
      %Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table{ecto_identifier: id} -> id
      _ ->
        case m.entity(ref) do
          %{ecto_identifier: id} ->
            Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table.write!(%Noizu.AdvancedScaffolding.Database.EctoIdentifierLookup.Table{identifier: ref, ecto_identifier: id})
            id
          _ -> nil
        end
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def universal_identifier_lookup(m, ref) do
    ref = m.ref(ref)
    case Noizu.AdvancedScaffolding.Database.UniversalLookup.Table.read!(ref) do
      %Noizu.AdvancedScaffolding.Database.UniversalLookup.Table{universal_identifier: id} -> id
    end
  end


end
