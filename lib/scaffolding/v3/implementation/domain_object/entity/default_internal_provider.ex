defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider do

  defmodule Default do

    @pii_levels %{
      level_0: 0,
      level_1: 1,
      level_2: 2,
      level_3: 3,
      level_4: 4,
      level_5: 5,
      level_6: 6,
    }

    def strip_pii(entity, max_level) do
      max_level = @pii_levels[max_level] || @pii_levels[:level_3]
      v = Enum.map(
        Map.from_struct(entity),
        fn ({field, value}) ->
          cond do
            (@pii_levels[entity.__struct__.__noizu_info__(:field_attributes)[field][:pii]] || @pii_levels[:level_6]) >= max_level -> {field, value}
            :else -> {field, :"*RESTRICTED*"}
          end
        end
      )
      struct(entity.__struct__, v)
    end

    def valid?(m, entity, context, options) do
      attributes = m.__noizu_info__(:field_attributes)
      field_errors = Enum.map(
                       Map.from_struct(entity),
                       fn ({field, value}) ->
                         # Required Check
                         field_attributes = attributes[field]
                         required = field_attributes[:required]
                         required_check = case required do
                                            true -> (value && true) || {:error, {:required, field}}
                                            {m, f} ->
                                              arity = Enum.max(Keyword.get_values(m.__info__(:functions), f))
                                              case arity do
                                                1 -> apply(m, f, [value])
                                                2 -> apply(m, f, [field, entity])
                                                3 -> apply(m, f, [field, entity, context])
                                                4 -> apply(m, f, [field, entity, context, options])
                                              end
                                            {m, f, arity} when is_integer(arity) ->
                                              case arity do
                                                1 -> apply(m, f, [value])
                                                2 -> apply(m, f, [field, entity])
                                                3 -> apply(m, f, [field, entity, context])
                                                4 -> apply(m, f, [field, entity, context, options])
                                              end
                                            {m, f, a} when is_list(a) -> apply(m, f, [field, entity] ++ a)
                                            {m, f, a} -> apply(m, f, [field, entity, a])
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
                                                       {:ref, domain_object, _identifier} ->
                                                         (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                       %{__struct__: domain_object} ->
                                                         (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:ref, {field, domain_object}}}
                                                       nil ->
                                                         cond do
                                                           required == true -> {:error, {:ref, {field, value}}}
                                                           :else -> true
                                                         end
                                                       _ ->
                                                         {:error, {:ref, {field, value}}}
                                                     end
                                                   {:struct, permitted} ->
                                                     case value do
                                                       %{__struct__: domain_object} ->
                                                         (permitted == :any || Enum.member?(permitted, domain_object)) || {:error, {:struct, {field, domain_object}}}
                                                       nil ->
                                                         cond do
                                                           required == true -> {:error, {:struct, {field, value}}}
                                                           :else -> true
                                                         end
                                                       _ ->
                                                         {:error, {:struct, {field, value}}}
                                                     end
                                                   {:enum, permitted} ->
                                                     et = permitted.__enum_type__
                                                     ee = permitted.__entity__
                                                     case value do
                                                       nil ->
                                                         cond do
                                                           required == true -> {:error, {:enum, {field, value}}}
                                                           :else -> true
                                                         end
                                                       {:ref, ^ee, _identifier} -> true
                                                       %{__struct__: ^ee} -> true
                                                       # %^ee{} breaks intellij parsing.
                                                       v when is_atom(v) -> et && Map.has_key?(et.atom_to_enum(), value) || {:error, {:enum, {field, value}}}
                                                       _ -> {:error, {:enum, {field, value}}}
                                                     end
                                                   {:atom, permitted} ->
                                                     case value do
                                                       nil ->
                                                         cond do
                                                           required == true -> {:error, {:enum, {field, value}}}
                                                           :else -> true
                                                         end
                                                       v when is_atom(v) -> (permitted == :any || Enum.member?(permitted, v)) || {:error, {:enum, {field, value}}}
                                                       _ -> {:error, {:enum, {field, value}}}
                                                     end
                                                   _ -> true
                                                 end

                         errors = Enum.filter(
                           [required_check, type_constraint_check],
                           fn (v) ->
                             case v do
                               {:error, _} -> true
                               _ -> false
                             end
                           end
                         )
                         length(errors) > 0 && {field, errors} || nil
                       end
                     )
                     |> Enum.filter(&(&1))

      cond do
        field_errors == [] -> true
        :else -> {:error, Map.new(field_errors)}
      end
    end
  end

  defmacro __using__(_options \\ nil) do
    quote do
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @__nzdo__internal_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider.Default

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      defdelegate strip_pii(entity, level), to: @__nzdo__internal_imp

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def valid?(%__MODULE__{} = entity, context, options \\ nil), do: @__nzdo__internal_imp.valid?(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def version_change(_vsn, entity, _context, _options \\ nil), do: entity

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      def version_change!(_vsn, entity, _context, _options \\ nil), do: entity


      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      defoverridable [
        strip_pii: 2,
        valid?: 2,
        valid?: 3,
        version_change: 3,
        version_change: 4,
        version_change!: 3,
        version_change!: 4,
      ]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      if (@__nzdo_persistence.ecto_entity) do
        if v = @__nzdo_persistence.options[:generate_reference_type] do
          cond do
            v == :enum_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
            v == :basic_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
            v == :universal_ref ->
              Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
            @__nzdo_persistence.options[:universal_reference] == false && @__nzdo_persistence.options[:enum_table] ->
              Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
            @__nzdo_persistence.options[:universal_reference] || @__nzdo_persistence.options[:universal_lookup] ->
              Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
            :else ->
              Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
          end
        end
      end
      if options = Module.get_attribute(@__nzdo__base, :enum_list) do
        Module.put_attribute(@__nzdo__base, :__nzdo_enum_field, options)
      end
    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
