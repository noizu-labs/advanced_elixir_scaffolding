defmodule Noizu.ElixirScaffolding.V3.Meta.Table do
  defmodule Default do

    #----------------------
    #
    #----------------------
    def expand_base(m, :auto) do
      b = Enum.slice(Module.split(m), 0..-2)
      Module.concat(b)
    end
    def expand_base(_, v), do: v

    #----------------------
    #
    #----------------------
    def expand_entity(m, :auto, base) do
      mod_split = Module.split(m)
      base = case base do
               :auto ->
                 ms = List.first(mod_split)
                 cond do
                   String.ends_with?(ms, "Schema") -> String.slice(ms, 0..-7)
                   :else -> ms
                 end
               v when is_atom(v) -> Atom.to_string(v) |> Macro.camelize()
               v when is_bitstring(v) -> v
             end
      ml = List.last(mod_split)
      inner = cond do
                ml == "Table" -> Enum.slice(mod_split, 2..-2)
                String.ends_with?(ml, "Table") -> Enum.slice(mod_split, 2..-2) ++ [String.slice(ml, 0..-7)]
                :else -> throw "#{__ENV__.file}:#{__ENV__.line} Unable to determine correct entity for #{m}, if table does not follow BaseSchema.DatabaseType.Entity.Path.Table manually pass the correct Entity module using the  entity: option"
              end
      Module.concat([base] ++ inner ++ ["Entity"] )
    end
    def expand_entity(_m, v, _b), do: v
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_table__(_caller, options) do
    provider = options[:provider] || Noizu.ElixirScaffolding.V3.Meta.Table.Default
    noizu_domain_object_schema = options[:noizu_domain_object_schema] || Application.get_env(:noizu_scaffolding, :domain_object_schema)
    nmid_source = options[:nmid_source] || :nmid_indexes
    app_name = options[:app_name] || :auto
    ecto_table = options[:ecto_table]
    disable_nmid = options[:disable_nmid] || false
    nmid_generator = options[:nmid_generator]
    nmid_sequencer = options[:nmid_sequencer]
    nmid_bare = options[:nmid_bare]
    auto_generate = options[:auto_generate]
    enum_list = options[:enum_list]
    is_enum_list = enum_list && true || false
    default_value = options[:default_value]
    ecto_type = options[:ecto_type]
    repo = options[:repo]
    no_entity = options[:entity] == false
    entity = options[:entity] || :auto
    base = options[:base] || :auto

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      import Ecto.Changeset
      require Noizu.DomainObject
      @__nzdo__table_provider unquote(provider)
      @__nzdo__ecto_table unquote(ecto_table)
      @enable_nmid  !unquote(disable_nmid)
      @__nzdo__no_entity_association (cond do
                                        unquote(no_entity) -> true
                                        Module.get_attribute(__MODULE__, :entity) == false -> true
                                        :else -> false
                                      end)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if !@__nzdo__no_entity_association do
        @__nzdo__entity @__nzdo__table_provider.expand_entity(__MODULE__, unquote(entity), unquote(app_name))
        @__nzdo__base @__nzdo__table_provider.expand_base(@__nzdo__entity, unquote(base))
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if @enable_nmid do
        @__nzdo__nmid_generator unquote(nmid_generator) || (Module.get_attribute(__MODULE__, :nmid_generator) || Noizu.Scaffolding.V3.NmidGenerator)
        @__nzdo__nmid_sequencer unquote(nmid_sequencer) || (Module.get_attribute(__MODULE__, :nmid_sequencer) || __MODULE__)
        @__nzdo__nmid_bare (cond do
                              unquote(nmid_bare) != nil -> unquote(nmid_bare)
                              Module.has_attribute?(__MODULE__, :nmid_bare) -> Module.get_attribute(__MODULE__, :nmid_bare)
                              :else -> false
                            end)
      end

      #----------------------
      # Load Persistence Settings from base, we need them to control some submodules.
      #----------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @__nzdo__enum_list unquote(is_enum_list) || Module.has_attribute?(__MODULE__, :enum_list) || false
      @__nzdo__auto_generate  (cond do
                                 unquote(auto_generate) != nil -> unquote(auto_generate)
                                 Module.has_attribute?(__MODULE__,:auto_generate) -> Module.get_attribute(__MODULE__, :auto_generate)
                                 @__nzdo__enum_list -> false
                                 :else -> true
                               end)
      if @__nzdo__enum_list do
        @__nzdo__enum_default_value unquote(default_value) || Module.get_attribute(__MODULE__, :default_value) || :none
        @__nzdo__enum_ecto_type unquote(ecto_type) || Module.get_attribute(__MODULE__, :ecto_type) || :integer
      end

      #-------------------------------
      # new
      #-------------------------------
      def new(options \\ %{}) do
        struct(__MODULE__, options)
      end

      #-------------------------------
      # validate_changeset
      #-------------------------------
      def validate_changeset(changeset, context, options) do
        case options[:custom_validation] do
          {m,f} -> apply(m, f, [changeset, context, options])
          {m,f,a} when is_list(a) -> apply(m, f, [changeset, context, options] ++ a)
          {m,f,a} -> apply(m, f, [changeset, context, options, a])
          lambda when is_function(lambda, 3) -> lambda.(changeset, context, options)
          nil ->
            changeset
            |> validate_required((options[:required] || []), options)
        end
      end

      #-------------------------------
      # changeset
      #-------------------------------
      def changeset(record, context, options \\ nil)
      def changeset(%{__struct__: __MODULE__} = record, context, options) do
        fields = Map.keys(struct(__MODULE__, [])) -- [:__struct__, :__schema__, :__meta__, :id, :identifier]
        record
        |> cast(Map.from_struct(record), fields)
        |> validate_changeset(context, options)
      end
      def changeset(record, context, options) when is_list(record) or is_map(record) do
        fields = Map.keys(struct(__MODULE__, [])) -- [:__struct__, :__schema__, :__meta__, :id, :identifier]
        record
        |> cast(record, fields)
        |> validate_changeset(context, options)
      end


      #----------------------
      #  __schema_table__
      #----------------------
      def __schema_table__(), do: @__nzdo__ecto_table

      if !@__nzdo__no_entity_association do
        #----------------------
        # modules
        #----------------------
        def __entity__(), do: @__nzdo__entity.__entity__()
        def __repo__(), do: @__nzdo__entity.__repo__()
        def __sref__(), do: @__nzdo__entity.__sref__()
        #----------------------
        # erp
        #----------------------
        def __erp__(), do: @__nzdo__entity.__erp__()

        #----------------------
        #  persistence
        #----------------------
        def __persistence__(), do:  @__nzdo__base.__persistence__()
        def __persistence__(setting), do:  @__nzdo__base.__persistence__(setting)
        def __persistence__(selector, setting), do:  @__nzdo__base.__persistence__(selector, setting)

        #----------------------
        #  __noizu_info__
        #----------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        if @__nzdo__enum_list do
          def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :enum_table)
          def __noizu_info__(:type), do: :enum_table
          def __noizu_info__(:persistence), do: __persistence__()
          def __noizu_info__(setting), do: @__nzdo__base.__noizu_info__(setting)
        else
          def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :entity_table)
          def __noizu_info__(:type), do: :entity_table
          def __noizu_info__(:persistence), do: __persistence__()
          def __noizu_info__(setting), do: @__nzdo__base.__noizu_info__(setting)
        end

        #----------------------
        #  __nmid__
        #----------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        if @enable_nmid do
          def __nmid__(), do: @__nzdo__base.__nmid__()
          def __nmid__(setting), do: @__nzdo__base.__nmid__(setting)
        end
      end

      if @__nzdo__no_entity_association do
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo__table_repo unquote(repo) || throw "#{__MODULE__} must specify repo option for non entity linked tables."

        #----------------------
        #  __noizu_info__
        #----------------------
        def __noizu_info__(), do: __noizu_info__(:all)
        def __noizu_info__(:all) do
          %{
            type: :table,
            base: nil, entity: nil, struct: nil, repo: nil,
            sref: nil, restrict_provider: nil, poly: nil,
            json_configuration: nil, identifier_type: nil, fields: nil,
            field_attributes: nil, field_types: nil, persistence: nil,
            associated_types: nil, indexing: nil, meta: nil,
          }
        end
        def __noizu_info__(:type), do: :table
        def __noizu_info__(:persistence), do: __persistence__()
        def __noizu_info__(_), do: nil

        #----------------------
        #  __persistence__
        #----------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo_persistence Noizu.DomainObject.expand_persistence_layers(Module.get_attribute(__MODULE__, :persistence_layers, [@__nzdo__table_repo]), __MODULE__)
        def __persistence__(), do: __persistence__(:all)
        def __persistence__(:all) do
          [:enum_table, :auto_generate, :universal_identifier, :universal_lookup, :reference_type, :layers, :schemas, :tables, :ecto_entity, :options]
          |> Enum.map(&({&1, __persistence__(&1)}))
          |> Map.new()
        end
        def __persistence__(:enum_table), do:  @__nzdo_persistence.options.enum_table
        def __persistence__(:auto_generate), do:  @__nzdo_persistence.options.auto_generate
        def __persistence__(:universal_identifier), do:  @__nzdo_persistence.options.universal_identifier
        def __persistence__(:universal_lookup), do:  @__nzdo_persistence.options.universal_lookup
        def __persistence__(:reference_type), do:  @__nzdo_persistence.options.generate_reference_type
        def __persistence__(:layers), do:  @__nzdo_persistence.layers
        def __persistence__(:schemas), do:  @__nzdo_persistence.schemas
        def __persistence__(:tables), do:  @__nzdo_persistence.tables
        def __persistence__(:ecto_entity), do:  @__nzdo_persistence.ecto_entity
        def __persistence__(:options), do:  @__nzdo_persistence.options
        def __persistence__(@__nzdo__table_repo, :table), do: __MODULE__
        def __persistence__(_, :table), do: nil

        if @enable_nmid do
          @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
          @__nzdo__noizu_domain_object_schema unquote(noizu_domain_object_schema) || throw "No-Entity Nmid enabled table require that noizu_domain_object_schema option or :noizu_scaffolding, :domain_object_schema value be provided"
          @nmid_source unquote(nmid_source)

          def __nmid__(), do: __nmid__(:all)
          def __nmid__(:all) do
            %{
              index: __nmid__(:index),
              generator: __nmid__(:generator),
              sequencer: __nmid__(:sequencer),
              bare: __nmid__(:bare)
            }
          end
          def __nmid__(:index) , do: @__nzdo__noizu_domain_object_schema.__noizu_info__(@nmid_source)[@__nzdo__nmid_sequencer]
          def __nmid__(:generator), do: @__nzdo__nmid_generator
          def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
          def __nmid__(:bare), do: @__nzdo__nmid_bare
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        new: 0,
        new: 1,
        validate_changeset: 3,
        changeset: 2,
        changeset: 3,
        __noizu_info__: 0,
        __noizu_info__: 1,
        __persistence__: 0,
        __persistence__: 1,
        __persistence__: 2,
        __schema_table__: 0,
      ]

      if @enable_nmid do
        defoverridable [__nmid__: 0, __nmid__: 1]
      end

      if !@__nzdo__no_entity_association do
        defoverridable [__entity__: 0, __repo__: 0, __sref__: 0, __erp__: 0]
      end

      @file __ENV__.file
    end
  end

end
