defmodule Noizu.ElixirScaffolding.V3.Meta.SimpleObject.Struct do

  def __noizu_struct__(caller, options, block) do

    index_provider = options[:index_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultIndexProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultInternalProvider
    persistence_provider = options[:persistence_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultPersistenceProvider
    macro_file = __ENV__.file
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]
                       require Noizu.DomainObject
                       require Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                       import Noizu.ElixirCore.Guards
                       @options unquote(options)
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(macro_file) <> "<single_call>"
                       if line = Module.get_attribute(__MODULE__, :__nzdo__struct_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_struct first defined on #{elem(line, 0)}:#{
                           elem(line, 1)
                         }"
                       end
                       @__nzdo__struct_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       # Extract Base Fields fields since SimbpleObjects are at the same level as their base.
                       @file unquote(macro_file) <> "<__prepare__base__macro__>"
                       @simple_object __MODULE__
                       Noizu.DomainObject.__prepare__base__macro__(@options)

                       # Push details to Base, and read in required settings.
                       @file unquote(macro_file) <> "<__prepare__poly__macro__>"
                       Noizu.DomainObject.__prepare__poly__macro__(@options)

                       # Load Sphinx Settings from base.
                       @file unquote(macro_file) <> "<__prepare__sphinx__macro__>"
                       Noizu.DomainObject.__prepare__sphinx__macro__(@options)

                       # Load Persistence Settings from base, we need them to control some submodules.
                       @file unquote(macro_file) <> "<__prepare__persistence_settings__macro__>"
                       Noizu.DomainObject.__prepare__persistence_settings__macro__(@options)

                       # Nmid
                       @file unquote(macro_file) <> "<__prepare__nmid__macro__>"
                       Noizu.DomainObject.__prepare__nmid__macro__(@options)

                       # Json Settings
                       @file unquote(macro_file) <> "<__prepare__json_settings__macro__>"
                       Noizu.DomainObject.__prepare__json_settings__macro__(@options)

                       #----------------------
                       # Derives
                       #----------------------
                       @__nzdo__derive Noizu.V3.EntityProtocol
                       @__nzdo__derive Noizu.V3.RestrictedProtocol

                       # Prep attributes for loading individual fields.
                       @file unquote(macro_file) <> "<__register__field_attributes__macro__>"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__register__field_attributes__macro__(@options)

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         @file unquote(macro_file) <> "<block>"
                         unquote(block)
                       after
                         :ok
                       end

                       @file unquote(macro_file) <> "<__post_struct_definition_macro__>"
                       Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__post_struct_definition_macro__(@options)


                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields

                 #---------------
                 # Poison
                 #---------------
                 if (@__nzdo__json_provider) do
                   __nzdo__json_provider = @__nzdo__json_provider
                   defimpl Poison.Encoder do
                     defdelegate encode(entity, options \\ nil), to: __nzdo__json_provider
                   end
                 end

                 #---------------
                 # Inspect
                 #---------------
                 defimpl Inspect do
                   defdelegate inspect(entity, opts), to: Noizu.ElixirScaffolding.V3.Meta.SimpleObject.Inspect
                 end
               end

    quote do
      unquote(process_config)
      unquote(generate)



      @file unquote(macro_file) <> "<index_provider>"
      use unquote(index_provider)
      @file unquote(macro_file) <> "<persistence_provider>"
      use unquote(persistence_provider)
      @file unquote(macro_file) <> "<internal_provider>"
      use unquote(internal_provider)

      @before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.SimpleObject.Struct
      #@after_compile unquote(internal_provider)
    end
  end

  defmacro __before_compile__(_) do
    quote do

      @__nzdo__poly_settings  %{
        poly: @__nzdo__poly?,
        support: @__nzdo__poly_support,
        base: @__nzdo__poly_base
      }
      @__nzdo__meta__map Map.new(@__nzdo__meta || [])



      #-------
      # type lookups
      #--------------
      def vsn(), do: @vsn
      def __base__(), do: @__nzdo__base
      def __object__(), do: __MODULE__

      #-------
      # __nmid__
      #--------------
      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all) do
        %{
          generator: __nmid__(:generator),
          sequencer: __nmid__(:sequencer),
          bare: __nmid__(:bare),
          index: __nmid__(:index),
        }
      end
      def __nmid__(:generator), do: @__nzdo__nmid_generator
      def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
      def __nmid__(:bare), do: @__nzdo__nmid_bare
      def __nmid__(:index), do: @__nzdo__nmid_index || @__nzdo__schema_helper.__noizu_info__(:nmid_indexes)[__MODULE__]

      #-------
      # __indexing__
      #--------------
      @__nzdo__indexes Enum.reduce(
                         List.flatten(@__nzdo__field_indexing || []),
                         @__nzdo__indexes,
                         fn ({{field, index}, indexing}, acc) ->
                           cond do
                             acc[index][:fields][field] == nil ->
                               put_in(acc, [index, :fields, field], indexing)
                             e = acc[index][:fields][field] ->
                               e = Enum.reduce(indexing, e, fn ({k, v}, acc) -> put_in(acc, [k], v) end)
                               put_in(acc, [index, :fields, field], e)
                           end
                         end
                       )

      def __indexing__(), do: __indexing__(:indexes)
      def __indexing__(:indexes), do: @__nzdo__indexes

      #-------
      # __persistence__
      #--------------
      @__nzdo_persistence Noizu.Scaffolding.V3.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
      def __persistence__(), do: __persistence__(:all)
      def __persistence__(:all), do: @__nzdo_persistence
      def __persistence__(:enum_table), do: @__nzdo_persistence.options.enum_table
      def __persistence__(:auto_generate), do: @__nzdo_persistence.options.auto_generate
      def __persistence__(:universal_identifier), do: @__nzdo_persistence.options.universal_identifier
      def __persistence__(:universal_lookup), do: @__nzdo_persistence.options.universal_lookup
      def __persistence__(:reference_type), do: @__nzdo_persistence.options.generate_reference_type
      def __persistence__(:layer), do: @__nzdo_persistence.layers
      def __persistence__(:schema), do: @__nzdo_persistence.schemas
      def __persistence__(:table), do: @__nzdo_persistence.tables
      def __persistence__(:ecto_entity), do: @__nzdo_persistence.ecto_entity
      def __persistence__(:options), do: @__nzdo_persistence.options
      def __persistence__(repo, :table), do: @__nzdo_persistence.schemas[repo] && @__nzdo_persistence.schemas[repo].table


      #-------
      # __noizu_info__
      #--------------
      @__nzdo_associated_types (
                                 Enum.map(@__nzdo_persistence__by_table || %{}, fn ({k, v}) -> {k, v.type} end) ++ Enum.map(
                                   @__nzdo__poly_support || %{},
                                   fn (k, v) -> {k, :poly} end
                                 ))
                               |> Map.new()
      @__nzdo__json_config put_in(@__nzdo__json_config, [:format_settings], @__nzdo__raw__json_format_settings)
      @__nzdo__field_attributes_map Map.new(@__nzdo__field_attributes)


      def __noizu_info__() do
        Enum.map(
          [
            :type,
            :base,
            :struct,
            :entity,
            :repo,
            :sref,
            :restrict_provider,
            :poly,
            :json_configuration,
            :identifier_type,
            :fields,
            :field_attributes,
            :field_types,
            :persistence,
            :associated_types,
            :indexing,
            :meta
          ],
          &({&1, __noizu_info__(&1)})
        )
      end

      def __noizu_info__(:type), do: :simple
      def __noizu_info__(:base), do: @__nzdo__base
      def __noizu_info__(:struct), do: __MODULE__
      def __noizu_info__(:restrict_provider), do: nil
      def __noizu_info__(:poly), do: @__nzdo__poly_settings
      def __noizu_info__(:json_configuration), do: @__nzdo__json_config
      def __noizu_info__(:identifier_type), do: @__nzdo__identifier_type
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:field_attributes), do: @__nzdo__field_attributes_map
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: __persistence__()
      def __noizu_info__(:associated_types), do: @__nzdo__entity.__noizu_info__(:associated_types)
      def __noizu_info__(:indexing), do: __indexing__()
      def __noizu_info__(:meta), do: @__nzdo__meta__map


    end
  end

end
