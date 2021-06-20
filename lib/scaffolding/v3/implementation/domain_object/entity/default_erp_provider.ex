defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider do

  #-----------------
  # id
  #-----------------
  def id(domain_object, {:ref, domain_object, id}), do: id
  def id(domain_object, ref) do
    case domain_object.ref(ref) do
      {:ref, _, id} -> id
      _ -> nil
    end
  end

  #------------------
  #
  #------------------
  def ref(_domain_object, nil), do: nil
  def ref(domain_object, %domain_object{identifier: identifier}), do: {:ref, domain_object, identifier}
  def ref(domain_object, %associated_struct{} = entity) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> associated_struct.ref(entity)
      config = domain_object.__persistence__(:table)[associated_struct] ->
        identifier = case config.map_id do
                       :unsupported -> nil
                       :same -> get_in(entity, [Access.key(:identifier)]) || get_in(entity, [Access.key(:id)])
                       {m,f} -> apply(m,f, [entity])
                       {m,f,a} when is_list(a) -> apply(m, f, [entity] ++ a)
                       {m,f,a} -> apply(m,f, [entity, a])
                       f when is_function(f,1) -> f.(entity)
                       _ -> nil
                     end
        identifier && {:ref, domain_object, identifier}
        :else -> nil
    end
  end
  def ref(domain_object, ref), do: domain_object.valid_identifier(ref) && {:ref, domain_object, ref}

  #------------------
  #
  #------------------
  def sref(domain_object, ref) do
    sref_name = domain_object.__sref__()
    identifier = domain_object.id(ref)
    cond do
      sref_name == :undefined -> nil
      identifier ->
        sref_identifier = domain_object.id_to_string(identifier) || throw "#{domain_object}.id_to_string failed for #{inspect identifier}"
        identifier_type = case domain_object.__noizu_info__(:identifier_type) do
                            identifier_type when is_tuple(identifier_type) -> elem(identifier_type, 0)
                            identifier_type -> identifier_type
                          end
        case identifier_type do
          :ref -> "ref.#{sref_name}{#{sref_identifier}}"
          :list -> "ref.#{sref_name}#{sref_identifier}"
          :compound -> "ref.#{sref_name}#{sref_identifier}"
          _other -> "ref.#{sref_name}.#{sref_identifier}"
        end
      :else -> nil
    end
  end

  # entity load
  def entity(domain_object, %domain_object{} = entity, _options), do: entity
  def entity(domain_object, %associated_struct{} = entity, options) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> entity
      config = domain_object.__persistence__(:table)[associated_struct] ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__from_record__(associated_struct, entity, context, options)
      :else -> nil
    end
  end
  def entity(domain_object, ref, options) do
    cond do
      ref = domain_object.ref(ref) ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__repo__().get(ref, context, options)
      :else -> nil
    end
  end

  def entity!(domain_object, %domain_object{} = entity, _options), do: entity
  def entity!(domain_object, %associated_struct{} = entity, options) do
    association_type = domain_object.__noizu_info__(:associated_types)[associated_struct]
    cond do
      association_type == nil -> nil
      association_type == false -> nil
      association_type == :poly -> entity
      config = domain_object.__persistence__(:table)[associated_struct] ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__from_record__!(associated_struct, entity, context, options)
      :else -> nil
    end
  end
  def entity!(domain_object, ref, options) do
    cond do
      ref = domain_object.ref(ref) ->
        context = Noizu.ElixirCore.CallingContext.system(options[:context] || Process.get(:context))
        domain_object.__repo__().get!(ref, context, options)
      :else -> nil
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __as_record__(domain_object, table, ref, context, options) do
    cond do
      entity = domain_object.entity(ref, options) ->
        layer = domain_object.__persistence__(:table)[table]
        cond do
          layer == nil -> throw "#{domain_object}.__as_record__ to table #{inspect table} not supported"
          layer.type == :mnesia -> domain_object.__as_mnesia_record__(table, entity, context, options)
          layer.type == :ecto -> domain_object.__as_ecto_record__(table, entity, context, options)
          layer.type == :redis -> domain_object.__as_redis_record__(table, entity, context, options)
          layer.type != domain_object && Kernel.function_exported?(layer.type, :__as_record__, 4) -> layer.type.__as_record__(table, entity, context, options)
          :else -> throw "#{domain_object}.__as_record__ layer.type (#{inspect layer.type}) not supported"
        end
      :else -> nil
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __as_record__!(domain_object, table, ref, context, options) do
    cond do
      entity = domain_object.entity!(ref, options) ->
        layer = domain_object.__persistence__(:table)[table]
        cond do
          layer == nil -> throw "#{domain_object}.__as_record__! to table #{inspect table} not supported"
          layer.type == :mnesia -> domain_object.__as_mnesia_record__!(table, entity, context, options)
          layer.type == :ecto -> domain_object.__as_ecto_record__!(table, entity, context, options)
          layer.type == :redis -> domain_object.__as_redis_record__!(table, entity, context, options)
          layer.type != domain_object && Kernel.function_exported?(layer.type, :__as_record__!, 4) -> layer.type.__as_record__!(table, entity, context, options)
          :else -> throw "#{domain_object}.__as_record__! layer.type (#{inspect layer.type}) not supported"
        end
      :else -> nil
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __as_mnesia_record__(domain_object, table, entity, context, options) do
    context = Noizu.ElixirCore.CallingContext.system(context)
    layer = domain_object.__persistence__(:table)[table]
    field_types = domain_object.__noizu_info__(:field_types)
    fields = Map.keys(table.__struct__([]))  -- [:__struct__, :__meta__]
    Enum.map(fields,
      fn(field) ->
        cond do
          field == :entity -> entity
          entry = layer.schema_fields[field] ->
            type = field_types[entry[:source]]
            source = case entry[:selector] do
                       nil -> get_in(entity, [Access.key(entry[:source])])
                       path when is_list(path) -> get_in(entity, path)
                       {m,f,a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                       {m,f,a} -> apply(m, f, [entry, entity, a])
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
      end)
    |> List.flatten()
    |> Enum.filter(&(&1))
    |> layer.table.__struct__()
  end

  def __as_mnesia_record__!(domain_object, table, ref, context, options) do
    domain_object.__as_mnesia_record__(table, ref, context, options)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __as_ecto_record__(domain_object, table, entity, context, options) do
    context = Noizu.ElixirCore.CallingContext.admin()
    layer = domain_object.__persistence__(:table)[table]
    field_types = domain_object.__noizu_info__(:field_types)
    Enum.map(domain_object.__noizu_info__(:fields),
      fn(field) ->
        cond do
          field == :identifier -> {:identifier, Noizu.Ecto.Entity.ecto_identifier(entity)}
          entry = layer.schema_fields[field] ->
            type = field_types[entry[:source]]
            source = case entry[:selector] do
                       nil -> get_in(entity, [Access.key(entry[:source])])
                       path when is_list(path) -> get_in(entity, path)
                       {m,f,a} when is_list(a) -> apply(m, f, [entry, entity] ++ a)
                       {m,f,a} -> apply(m, f, [entry, entity, a])
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
      end)
    |> List.flatten()
    |> Enum.filter(&(&1))
    |> layer.table.__struct__()
  end

  def __as_ecto_record__!(domain_object, table, ref, context, options) do
    domain_object.__as_ecto_record__(table, ref, context, options)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __as_redis_record__(m, table, entity, context, options) do
    raise "NYI"
  end

  def __as_redis_record__!(m, table, ref, context, options) do
    raise "NYI"
  end

  #-----------------------------------
  #
  #-----------------------------------
  def __from_record__(m, _type, %{entity: temp}, context,  _options) do
    temp
  end
  def __from_record__(m, _type, %{entity: temp}, context,  _options) do
    nil
  end

  def __from_record__!(m, _type, _, context, _options) do
    nil
  end
  def __from_record__(m, _type, _, context,  _options) do
    nil
  end

  #-----------------------------------
  #
  #-----------------------------------
  def sref_section_regex(_, :integer), do: "([0-9]*)"
  def sref_section_regex(_, :string), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(_, :hash), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(_, :uuid), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(m, {:list, template}), do: "(\[((" <> m.sref_section_regex(template) <> ",?)+)\])"
  def sref_section_regex(m, {:compound, template, _}), do: m.sref_section_regex({:compound, template})
  def sref_section_regex(m, {:compound, template}), do: "(\{" <> Enum.join(Enum.map(template, &(m.sref_section_regex(&1))), ",")  <>  "\})"
  def sref_section_regex(m, {:atom, _c}), do: m.sref_section_regex(:atom)
  def sref_section_regex(_, :atom), do: "([a-z_A-Z0-9]*)"
  def sref_section_regex(m, {:ref, _c}), do: m.sref_section_regex(:ref)
  def sref_section_regex(_, :ref), do: "(ref\.[a-z0-9\-]+\{[a-z_\-0-9@,.]+\}|ref\.[a-z0-9\-]+\.[a-z_\-0-9@.]+)"

  #-----------------------------------
  #
  #-----------------------------------
  def id_to_string(_m, _, nil), do: nil
  def id_to_string(_m, :integer, id) when is_integer(id), do: Integer.to_string(id)
  def id_to_string(_m, :string, id) when is_bitstring(id), do: id
  def id_to_string(_m, :hash, id) when is_bitstring(id), do: id
  def id_to_string(_m, :uuid, id), do: UUID.binary_to_string!(id)
  def id_to_string(m, {:list, template}, id) do
    "[" <> (Enum.map(id, &(m.id_to_string(template, &1))) |> Enum.join(",")) <> "]"
  end
  def id_to_string(m, {:compound, template, prep}, id) do
    case prep do
      prep when is_function(prep, 2) -> m.id_to_string({:compound, template}, prep.(:encode, id))
      {m,f} -> m.id_to_string({:compound, template}, apply(m, f, [:encode, id]))
      _ -> throw "invalid compound id formatter"
    end
  end
  def id_to_string(m, {:compound, template}, id) do
    template_list = Tuple.to_list(template)
    id_list = Tuple.to_list(id)
    length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
    l = Enum.map_reduce(id_list, 0, &( {m.id_to_string(Enum.at(template_list, &2), &1), &2 + 1}))
    "{" <> Enum.join(l, ",") <> "}"
  end
  def id_to_string(_m, :atom, id), do: Atom.to_string(id)
  def id_to_string(_m, {:atom, :existing}, id), do: Atom.to_string(id)
  def id_to_string(_m, {:atom, constraint}, id) do
    sref = case constraint do
             v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             {m,f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             _ -> throw "invalid atom constraint #{inspect constraint}"
           end
    "[#{sref}]"
  end
  def id_to_string(_m, :ref, id), do: Noizu.ERP.sref(id) || throw "invalid ref"
  def id_to_string(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    case constraint do
      v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
      {m,f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
      _ -> throw "invalid ref constraint #{inspect constraint}"
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def string_to_id(_m, _, nil), do: nil
  def string_to_id(_m, _, id) when not is_bitstring(id), do: throw "invalid sref id part #{inspect id}"
  def string_to_id(_m, :integer, id), do: String.to_integer(id)
  def string_to_id(_m, :string, id), do: id
  def string_to_id(_m, :hash, id), do: id
  def string_to_id(_m, :uuid, id), do: UUID.string_to_binary!(id)
  def string_to_id(m, {:list, template}, id) do
    r = Regex.compile(m.sref_section_regex(template))
    case Regex.split(r, id, :include_captures) do
      v when is_list(v) and length(v) > 0 ->
        Enum.filter(v, &(!Enum.member?(["[", ",", "]"], &1)) )
        |> Enum.map(&(m.string_to_id(template, &1)))
      _ -> throw "invalid sref id part #{inspect id}"
    end
  end
  def string_to_id(m, {:compound, template, prep}, id) do
    formatted = m.string_to_id({:compound, template}, id)
    case prep do
      prep when is_function(prep, 2) -> prep.(:decode, formatted)
      {m,f} -> apply(m, f, [:decode, formatted])
      _ -> throw "invalid compound id formatter"
    end
  end
  def string_to_id(m, {:compound, template}, id) do
    template_list = Tuple.to_list(template)
    id_list = Tuple.to_list(id)
    length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
    extract = Enum.map(template, &(m.sref_section_regex(&1)))
              |> Enum.join(",")
    extract = Regex.compile("^{" <> extract <> "}")
    case Regex.run(extract, id) do
      nil -> throw "vinalid compind id #{extract.source}"
      [] -> throw "vinalid compind id #{extract.source}"
      v when is_list(v) ->
        length(v) != length(template_list) && throw "malformed compound id: #{inspect id}"
        Enum.map(v, &(m.string_to_id(Enum.at(template_list, &2), &1))) |> List.to_tuple()
    end
  end
  def string_to_id(_m, :atom, id), do: Atom.to_string(id)
  def string_to_id(_m, {:atom, :existing}, id), do: Atom.to_string(id)
  def string_to_id(_m, {:atom, constraint}, id) do
    sref = case constraint do
             v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             {m,f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             _ -> throw "invalid atom constraint #{inspect constraint}"
           end
    "[#{sref}]"
  end
  def string_to_id(_m, :ref, id), do: Noizu.ERP.sref(id) || throw "invalid ref"
  def string_to_id(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    case constraint do
      v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
      {m,f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
      _ -> throw "invalid ref constraint #{inspect constraint}"
    end
  end

  def record(_, _ref, _options), do: nil
  def record!(_, _ref, _options), do: nil

  def valid?(m, entity, context, options) do
    attributes = m.__noizu_info__(:field_attributes)
    field_errors = Enum.map(Map.from_struct(entity),
                     fn({field, value}) ->
                       # Required Check
                       field_attributes = attributes[field]
                       required = field_attributes[:required]
                       required_check = case required do
                                          true -> (value && true) || {:error, {:required, field}}
                                          {m,f} ->
                                            arity = Enum.max(Keyword.get_values(m.__info__(:functions), f))
                                            case arity do
                                              1 -> apply(m, f, [value])
                                              2 -> apply(m, f, [field, entity])
                                              3 -> apply(m, f, [field, entity, context])
                                              4 -> apply(m, f, [field, entity, context, options])
                                            end
                                          {m,f, arity} when is_integer(arity) ->
                                            case arity do
                                              1 -> apply(m, f, [value])
                                              2 -> apply(m, f, [field, entity])
                                              3 -> apply(m, f, [field, entity, context])
                                              4 -> apply(m, f, [field, entity, context, options])
                                            end
                                          {m,f,a} when is_list(a) -> apply(m, f, [field, entity] ++ a)
                                          {m,f,a} -> apply(m, f, [field, entity, a])
                                          f when is_function(f, 1) -> f.([value])
                                          f when is_function(f, 2) -> f.([field, entity])
                                          f when is_function(f, 3) -> f.([field, entity, context])
                                          f when is_function(f, 4) -> f.([field, entity, context, options])
                                          false -> true
                                          nil -> true
                                        end

                       # Type Constraint Check
                       type_constraint_check = case field_attributes[:type_constraint] do
                                                 {:ref, permitted} ->
                                                   case value do
                                                     {:ref, domain_object, _identifier} -> (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                     %domain_object{} -> (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                     nil ->
                                                       cond do
                                                         required == true ->  {:error, {:ref, {field, value}}}
                                                         :else -> true
                                                       end
                                                     _ -> {:error, {:ref, {field, value}}}
                                                   end
                                                 {:struct, permitted} ->
                                                   case value do
                                                     %domain_object{} -> (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:struct, {field, domain_object}}}
                                                     nil ->
                                                       cond do
                                                         required == true ->  {:error, {:struct, {field, value}}}
                                                         :else -> true
                                                       end
                                                     _ -> {:error, {:struct, {field, value}}}
                                                   end
                                                 {:enum, permitted} ->
                                                   et = permitted.__enum_type__
                                                   ee = permitted.__entity__
                                                   case value do
                                                     nil ->
                                                       cond do
                                                         required == true ->  {:error, {:enum, {field, value}}}
                                                         :else -> true
                                                       end
                                                     {:ref, ^ee, _identifier} -> true
                                                     %{__struct__: ^ee} -> true  # %^ee{} breaks intellij parsing.
                                                     v when is_atom(v) -> et && Map.has_key?(et.atom_to_enum(), value) || {:error, {:enum, {field, value}}}
                                                     _ -> {:error, {:enum, {field, value}}}
                                                   end
                                                 {:atom, permitted} ->
                                                   case value do
                                                     nil ->
                                                       cond do
                                                         required == true ->  {:error, {:enum, {field, value}}}
                                                         :else -> true
                                                       end
                                                     v when is_atom(v) -> (permitted == :any || Enum.member?(permitted, v)) || {:error, {:enum, {field, value}}}
                                                     _ -> {:error, {:enum, {field, value}}}
                                                   end
                                                 _ -> true
                                               end

                       errors = Enum.filter([required_check, type_constraint_check], fn(v) ->
                         case v do
                           {:error, _} -> true
                           _ -> false
                         end
                       end)
                       length(errors) > 0 && {field, errors} || nil
                     end
                   ) |> Enum.filter(&(&1))

    cond do
      field_errors == [] -> true
      :else -> {:error, Map.new(field_errors)}
    end
  end


  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__erp_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider
      #-----------------------------------
      #
      #-----------------------------------
      def __sref_prefix__, do: "ref.#{@__nzdo__sref}."

      def valid_identifier(_), do: true

      #-----------------------------------
      # ERP
      #-----------------------------------
      # id
      #-----------------
      def id("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.id(__MODULE__.ref(ref))
      def id(ref), do: @__nzdo__erp_imp.id(__MODULE__, ref)
      # ref
      #-----------------
      def ref("ref.#{@__nzdo__sref}{" <> id) do
        identifier = string_to_id(String.slice(id, 0..-2))
        identifier && {:ref, __MODULE__, identifier}
      end
      def ref("ref.#{@__nzdo__sref}." <> id) do
        identifier = string_to_id(id)
        identifier && {:ref, __MODULE__, identifier}
      end
      def ref(ref), do: @__nzdo__erp_imp.ref(__MODULE__, ref)
      # sref
      #-----------------
      def sref("ref.#{@__nzdo__sref}" <> _ = ref), do: ref
      def sref(ref), do: @__nzdo__erp_imp.sref(__MODULE__, ref)
      # entity
      #-----------------
      def entity("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity(__MODULE__.ref(ref))
      def entity(ref, options \\ nil), do: @__nzdo__erp_imp.entity(__MODULE__, ref, options)
      # entity!
      #-----------------
      def entity!("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity!(__MODULE__.ref(ref))
      def entity!(ref, options \\ nil), do: @__nzdo__erp_imp.entity!(__MODULE__, ref, options)
      # record
      #-----------------
      def record("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.record(__MODULE__.ref(ref))
      def record(ref, options \\ nil), do: @__nzdo__erp_imp.record(__MODULE__, ref, options)
      # record!
      #-----------------
      def record!("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.record!(__MODULE__.ref(ref))
      def record!(ref, options \\ nil), do: @__nzdo__erp_imp.record!(__MODULE__, ref, options)

      #---------------------
      #
      #---------------------
      def sref_section_regex(type), do: @__nzdo__erp_imp.sref_section_regex(__MODULE__, type)

      def id_to_string(type, id), do: @__nzdo__erp_imp.id_to_string(__MODULE__, type, id)
      def id_to_string(id), do: @__nzdo__erp_imp.id_to_string(__MODULE__, @__nzdo__identifier_type, id)

      def string_to_id(id), do: @__nzdo__erp_imp.string_to_id(__MODULE__, @__nzdo__identifier_type, id)
      def string_to_id(type, id), do: @__nzdo__erp_imp.string_to_id(__MODULE__, type, id)


      def __as_record__(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_record__(__MODULE__, table, entity, context, options)
      def __as_record__!(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_record__!(__MODULE__, table, entity, context, options)
      def __as_mnesia_record__(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_mnesia_record__(__MODULE__, table, entity, context, options)
      def __as_mnesia_record__!(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_mnesia_record__!(__MODULE__, table, entity, context, options)
      def __as_ecto_record__(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_ecto_record__(__MODULE__, table, entity, context, options)
      def __as_ecto_record__!(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_ecto_record__!(__MODULE__, table, entity, context, options)

      def __as_redis_record__(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_redis_record__(__MODULE__, table, entity, context, options)
      def __as_redis_record__!(table, entity, context, options \\ nil), do:  @__nzdo__erp_imp.__as_redis_record__!(__MODULE__, table, entity, context, options)

      def __from_record__(type, record, context, options \\ nil), do:  @__nzdo__erp_imp.__from_record__(__MODULE__, type, record, context, options)
      def __from_record__!(type, record, context, options \\ nil), do:  @__nzdo__erp_imp.__from_record__!(__MODULE__, type, record, context, options)

      #====================================================
      # These should be move into their own modules.
      #====================================================
      def __write_index__(entity, _context, _options \\ nil) do
        IO.puts "TODO - #{__MODULE__} - iterate over indexes (if any) and call their insert methods."
      end
      def __update_index__(entity, _context, _options \\ nil) do
        IO.puts "TODO - #{__MODULE__} - iterate over indexes (if any) and call their update methods."
      end
      def __delete_index__(entity, _context, _options \\ nil) do
        IO.puts "TODO - #{__MODULE__} - iterate over indexes (if any) and call their delete methods."
      end

      def valid?(%__MODULE__{} = entity, context, options \\ nil) , do:  @__nzdo__erp_imp.valid?(__MODULE__, entity, context, options)


      defoverridable [
        id: 1,
        ref: 1,
        sref: 1,
        entity: 1,
        entity: 2,
        entity!: 1,
        entity!: 2,
        record: 1,
        record: 2,
        record!: 1,
        record!: 2,
        sref_section_regex: 1,
        id_to_string: 1,
        id_to_string: 2,
        string_to_id: 1,
        string_to_id: 2,

        __as_record__: 3,
        __as_record__: 4,
        __as_record__!: 3,
        __as_record__!: 4,
        __as_mnesia_record__: 3,
        __as_mnesia_record__: 4,
        __as_mnesia_record__!: 3,
        __as_mnesia_record__!: 4,
        __as_ecto_record__: 3,
        __as_ecto_record__: 4,
        __as_ecto_record__!: 3,
        __as_ecto_record__!: 4,
        __as_redis_record__: 3,
        __as_redis_record__: 4,
        __as_redis_record__!: 3,
        __as_redis_record__!: 4,
        __from_record__: 3,
        __from_record__: 4,
        __from_record__!: 3,
        __from_record__!: 4,


        __write_index__: 2,
        __write_index__: 3,
        __update_index__: 2,
        __update_index__: 3,
        __delete_index__: 2,
        __delete_index__: 3,

        valid?: 2,
        valid?: 3,
      ]
    end
  end

end
