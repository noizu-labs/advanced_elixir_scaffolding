defmodule Noizu.AdvancedScaffolding.Internal.Persistence.Entity do
  @moduledoc """
  Persistence Functionality
  """



  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types

    @callback ecto_entity?() :: boolean
    @callback source(any) :: any
    @callback universal_identifier(Types.entity_or_ref) :: nil | integer
    @callback ecto_identifier(Types.entity_or_ref) :: integer | nil

    @callback __as_record__(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil
    @callback __as_record__!(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil

    @callback __from_record__(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil
    @callback __from_record__!(layer :: Noizu.AdvancedScaffolding.Schema.PersistenceLayer.t | atom, Types.entity_or_ref, Noizu.ElixirCore.CallingContext.t, Types.options) :: map() | nil


    @callback __persistence__() :: any
    @callback __persistence__(any) :: any
    @callback __persistence__(any, any) :: any

    @callback __nmid__() :: any
    @callback __nmid__(any) :: any

    def __configure__(options) do
      quote do

        # Load Persistence Settings from base, we need them to control some submodules.
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__persistence_settings__macro__(unquote(options))

        # Nmid
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        Noizu.AdvancedScaffolding.Internal.Helpers.__prepare__nmid__macro__(unquote(options))

      end
    end

    def __implement__(options) do
      core_implementation = options[:core_implementation] || Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Implementation.Default
      quote do
        alias Noizu.AdvancedScaffolding.Schema.PersistenceLayer
        @behaviour Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour
        @nzdo__persistence_implementation unquote(core_implementation)

        #=======================================
        # Persistence
        #=======================================
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __as_record__(%PersistenceLayer{} = layer, entity, context, options \\ nil), do: @nzdo__persistence_implementation.__as_record__(__MODULE__, layer, entity, context, options)
        def __as_record__!(%PersistenceLayer{} = layer, entity, context, options \\ nil), do: @nzdo__persistence_implementation.__as_record__!(__MODULE__, layer, entity, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __from_record__(%PersistenceLayer{} = layer, record, context, options \\ nil), do: @nzdo__persistence_implementation.__from_record__(__MODULE__, layer, record, context, options)
        def __from_record__!(%PersistenceLayer{} = layer, record, context, options \\ nil), do: @nzdo__persistence_implementation.__from_record__!(__MODULE__, layer, record, context, options)


        if (@__nzdo_persistence.ecto_entity) do
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def ecto_entity?(), do: true

          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          cond do
            Module.has_attribute?(__MODULE__, :__nzdo__ecto_identifier_field) -> def ecto_identifier(ref), do: @nzdo__persistence_implementation.ecto_identifier(__MODULE__, ref)
            Module.get_attribute(__MODULE__, :__nzdo__identifier_type) == :integer -> def ecto_identifier(ref), do: __MODULE__.id(ref)
            :else -> def ecto_identifier(_), do: raise "Not Supported"
          end

          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def source(_), do: @__nzdo_persistence.ecto_entity

          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          cond do
            @__nzdo_persistence.options[:universal_identifier] -> def universal_identifier(ref), do: __MODULE__.id(ref)
            @__nzdo_persistence.options[:universal_lookup] -> def universal_identifier(ref), do: @nzdo__persistence_implementation.universal_identifier_lookup(__MODULE__, ref)
            :else -> def universal_identifier(_), do: raise "Not Supported"
          end
        else
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          def ecto_entity?(), do: false
          def ecto_identifier(_), do: nil
          def source(_), do: nil
          def universal_identifier(_), do: nil
        end


        defoverridable [
          ecto_entity?: 0,
          ecto_identifier: 1,
          universal_identifier: 1,
          source: 1,

          __as_record__: 3,
          __as_record__: 4,
          __as_record__!: 3,
          __as_record__!: 4,
          __from_record__: 3,
          __from_record__: 4,
          __from_record__!: 3,
          __from_record__!: 4,
        ]

      end
    end


    defmacro __before_compile__(_env) do
      quote do
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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




        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo_persistence Noizu.AdvancedScaffolding.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
        if @__nzdo__base_open? do
          Module.put_attribute(@__nzdo__base, :__nzdo_persistence, @__nzdo_persistence)
        end



        #################################################
        # __persistence__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @doc """
           Entity persistence settings (various databases read or written to when updating/fetching a domain object entity.)"
        """
        def __persistence__(), do: __persistence__(:all)
        @doc """
           Entity persistence settings (various databases read or written to when updating/fetching a domain object entity.)"
        """
        def __persistence__(:all) do
          [:enum_table, :auto_generate, :universal_identifier, :universal_lookup, :reference_type, :layers, :schemas, :tables, :ecto_entity, :options]
          |> Enum.map(&({&1, __persistence__(&1)}))
          |> Map.new()
        end
        def __persistence__(:ecto_type), do: @__nzdo__enum_ecto_type
        def __persistence__(:enum_table), do: @__nzdo_persistence.options.enum_table
        def __persistence__(:auto_generate), do: @__nzdo_persistence.options.auto_generate
        def __persistence__(:universal_identifier), do: @__nzdo_persistence.options.universal_identifier
        def __persistence__(:universal_lookup), do: @__nzdo_persistence.options.universal_lookup
        def __persistence__(:reference_type), do: @__nzdo_persistence.options.generate_reference_type
        def __persistence__(:layers), do: @__nzdo_persistence.layers
        def __persistence__(:schemas), do: @__nzdo_persistence.schemas
        def __persistence__(:tables), do: @__nzdo_persistence.tables
        def __persistence__(:ecto_entity), do: @__nzdo_persistence.ecto_entity
        def __persistence__(:options), do: @__nzdo_persistence.options
        def __persistence__(repo, :table), do: @__nzdo_persistence.schemas[repo] && @__nzdo_persistence.schemas[repo].table

        #################################################
        # __nmid__
        #################################################
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @doc """
          Unique Identifier Generator Config Settings .
        """
        def __nmid__(), do: __nmid__(:all)
        @doc """
          Unique Identifier Generator Config Settings .
        """
        def __nmid__(:all) do
          %{
            generator: __nmid__(:generator),
            sequencer: __nmid__(:sequencer),
            bare: __nmid__(:bare),
            index: __nmid__(:index),
          }
        end
        if @__nzdo__nmid_index do
          def __nmid__(:index) do
            @__nzdo__nmid_index
          end
        else
          def __nmid__(:index) do
            cond do
              !@__nzdo__schema_helper ->
                {f,a} = __ENV__.function
                raise """
                #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - nmid_index required to generate node/entity unique identifiers.
                You must pass in noizu_domain_object_schema to the Entity, set the noizu_scaffolding: DomainObjectSchema config option (@see Noizu.AdvancedScaffolding.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider.Default)
                Or specify a one off for this specific table by adding @nmid_index annotation or [nmid_index: value] to the DomainObject.noizu_entity or derived macro.
                """
              v = Kernel.function_exported?(@__nzdo__schema_helper, :__noizu_info__, 1) && apply(@__nzdo__schema_helper, :__noizu_info__, [:nmid_indexes])[__MODULE__] -> v
              v = Kernel.function_exported?(@__nzdo__schema_helper, :__noizu_info__, 1) && apply(@__nzdo__schema_helper, :__noizu_info__, [:nmid_indexes]) ->
                {f,a} = __ENV__.function
                raise """
                #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - schema helper has no nmid_index entry for #{__MODULE__}}.
                Update schema helper (#{@__nzdo__schema_helper}) or provide a one off declaration @nmid_index 123.
                """
              :else ->
                {f,a} = __ENV__.function
                raise """
                #{__MODULE__}.#{f}/#{a}:#{unquote(__ENV__.line)}@#{__MODULE__} - nmid_index not supported by schema helper.
                Update schema helper (#{@__nzdo__schema_helper}) or provide a one off declaration @nmid_index 123.
                """
            end
          end
        end
        def __nmid__(setting), do: @__nzdo__base.__nmid__(setting)


      end
    end


    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end

  end
end
