defmodule Noizu.DomainObject do

  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    nmid_generator = options[:nmid_generator]
    nmid_sequencer = options[:nmid_sequencer]
    nmid_index = options[:nmid_index]
    auto_generate = options[:auto_generate]
    caller = __CALLER__
    internal_provider = options[:internal_provider] || Noizu.ElixirScaffolding.V3.Meta.DomainObject
    quote do
      import Noizu.DomainObject, only: [file_rel_dir: 1]
      Module.register_attribute(__MODULE__, :index, accumulate: true)
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__entity, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__struct, accumulate: false)
      Module.register_attribute(__MODULE__, :json_white_list, accumulate: false)
      Module.register_attribute(__MODULE__, :json_format_group, accumulate: true)
      Module.register_attribute(__MODULE__, :json_field_group, accumulate: true)
      Module.register_attribute(__MODULE__, :poly_support, accumulate: true)

      # Insure only referenced once.
      if line = Module.get_attribute(__MODULE__, :__nzdo__base_definied) do
        raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} duplicate use Noizu.DomainObject reference. First defined on #{elem(line, 0)}:#{elem(line, 1)}"
      end
      @__nzdo__base_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

      if v = unquote(nmid_generator) do
        Module.put_attribute(__MODULE__, :nmid_generator, v)
      end
      if v = unquote(nmid_sequencer) do
        Module.put_attribute(__MODULE__, :nmid_sequencer, v)
      end
      if v = unquote(nmid_index) do
        Module.put_attribute(__MODULE__, :nmid_index, v)
      end
      if unquote(auto_generate) != nil do
        Module.put_attribute(__MODULE__, :auto_generate, unquote(auto_generate))
      end
      @before_compile unquote(internal_provider)
    end
  end



  #--------------------------------------------
  # noizu_table
  #--------------------------------------------
  defmacro noizu_table(options \\ []) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.Table.__noizu_table__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_scaffolding_schema
  #--------------------------------------------
  defmacro noizu_scaffolding_schema(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.ScaffoldingSchema.__noizu_scaffolding_schema__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_type_handler
  #--------------------------------------------
  defmacro noizu_type_handler(options \\ []) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.TypeHandler.__noizu_type_handler__(__CALLER__, options)
  end


  #--------------------------------------------
  # noizu_entity
  #--------------------------------------------
  defmacro noizu_entity(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
  end


  #--------------------------------------------
  # noizu_index
  #--------------------------------------------
  defmacro noizu_index(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index.__noizu_index__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_sphinx
  #--------------------------------------------
  defmacro noizu_sphinx(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Sphinx.__noizu_sphinx__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_struct
  #--------------------------------------------
  defmacro noizu_struct(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.SimpleObject.Struct.__noizu_struct__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_repo
  #--------------------------------------------
  defmacro noizu_repo(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # file_rel_dir
  #--------------------------------------------
  def file_rel_dir(module_path) do
    offset = file_rel_dir(__ENV__.file, module_path, 0)
    String.slice(module_path, offset..- 1)
  end
  def file_rel_dir(<<m>> <> a, <<m>> <> b, acc) do
    file_rel_dir(a, b, 1 + acc)
  end
  def file_rel_dir(_a, _b, acc), do: acc

  #--------------------------------------------
  # module_rel
  #--------------------------------------------
  def module_rel(base, module_path) do
    [_ | a] = base
    [_ | b] = module_path
    offset = module_rel(a, b, 0)
    Enum.slice(module_path, (offset + 1)..- 1)
  end
  def module_rel([h | a], [h | b], acc) do
    module_rel(a, b, 1 + acc)
  end
  def module_rel(_a, _b, acc), do: acc


  #--------------------------------------------
  # expand_indexes
  #--------------------------------------------
  defdelegate expand_indexes(layers, module), to: Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index

  #--------------------------------------------
  # expand_persistence_layers
  #--------------------------------------------
  defdelegate expand_persistence_layers(layers, module), to: Noizu.ElixirScaffolding.V3.Meta.Persistence


  #--------------------------------------------
  # extract_transform_attribute
  #--------------------------------------------
  defmacro extract_transform_attribute(attribute, setting, mfa, default \\ nil) do
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) ->
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(setting)) -> @__nzdo__base.__noizu_info__(unquote(setting))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__base, unquote(attribute))
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(setting)) -> @__nzdo__poly_base.__noizu_info__(unquote(setting))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
        :else ->
          v = unquote(default)
          {m, f, a} = unquote(mfa)
          apply(m, f, [v] ++ a)
      end
    end
  end

  #--------------------------------------------
  # extract_has_attribute
  #--------------------------------------------
  defmacro extract_has_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(property)) != nil -> @__nzdo__base.__noizu_info__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(property)) != nil -> @__nzdo__poly_base.__noizu_info__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end



  #--------------------------------------------
  # extract_has_json_attribute
  #--------------------------------------------
  defmacro extract_has_json_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__json__(unquote(property)) != nil -> @__nzdo__base.__json__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__json__(unquote(property)) != nil -> @__nzdo__poly_base.__json__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # extract_has_enum_attribute
  #--------------------------------------------
  defmacro extract_has_enum_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__enum__(unquote(property)) != nil -> @__nzdo__base.__enum__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__enum__(unquote(property)) != nil -> @__nzdo__poly_base.__enum__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end



  #--------------------------------------------
  # extract_has_nmid_attribute
  #--------------------------------------------
  defmacro extract_has_nmid_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__nmid__(unquote(property)) != nil -> @__nzdo__base.__nmid__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__nmid__(unquote(property)) != nil -> @__nzdo__poly_base.__nmid__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end




  #--------------------------------------------
  # extract_has_persistence_attribute
  #--------------------------------------------
  defmacro extract_has_persistence_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        Module.has_attribute?(__MODULE__, unquote(attribute)) -> Module.get_attribute(__MODULE__, unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__persistence__(unquote(property)) != nil -> @__nzdo__base.__persistence__(unquote(property))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__persistence__(unquote(property)) != nil -> @__nzdo__poly_base.__persistence__(unquote(property))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end

  #--------------------------------------------
  # extract_attribute
  #--------------------------------------------
  defmacro extract_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) -> v
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(unquote(property)) -> @__nzdo__base.__noizu_info__(unquote(property))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(unquote(property)) -> @__nzdo__poly_base.__noizu_info__(unquote(property))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #--------------------------------------------
  # extract_json_attribute
  #--------------------------------------------
  defmacro extract_json_attribute(attribute, property \\ nil, default) do
    property = property || attribute
    quote do
      cond do
        v = Module.get_attribute(__MODULE__, unquote(attribute)) -> v
        !@__nzdo__base_open? && @__nzdo__base.__json__(unquote(property)) -> @__nzdo__base.__json__(unquote(property))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__json__(unquote(property)) -> @__nzdo__poly_base.__json__(unquote(property))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end


  #----------------------------------------------------
  # __prepare__base__macro__
  #----------------------------------------------------
  defmacro __prepare__base__macro__(options) do
    quote do
      base = unquote(options)[:base]

      @__nzdo__base base || Module.get_attribute(__MODULE__, :simple_object) || (
        Module.split(__MODULE__)
        |> Enum.slice(0..-2)
        |> Module.concat())
      @__nzdo__base_open? Module.open?(@__nzdo__base)
      @base_meta ((Module.has_attribute?(@__nzdo__base, :meta) && Module.get_attribute(@__nzdo__base, :meta) || []))
      Module.delete_attribute(__MODULE__, :meta)
      Module.register_attribute(__MODULE__, :meta, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)


      Module.register_attribute(__MODULE__, :__nzdo__entity, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__struct, accumulate: false)

      if @__nzdo__base_open? && !(Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) || Module.get_attribute(@__nzdo__base, :__nzdo__simple_definied))do
        raise "#{@__nzdo__base} must include use Noizu.SimpleObject/DomainObject call."
      end
    end
  end

  #----------------------------------------------------
  # __prepare__poly__macro__
  #----------------------------------------------------
  defmacro __prepare__poly__macro__(options) do
    quote do
      options = unquote(options)
      noizu_domain_object_schema = options[:noizu_domain_object_schema] || Application.get_env(:noizu_scaffolding, :domain_object_schema)
      poly_base = options[:poly_base]
      poly_support = options[:poly_support]
      repo = options[:repo]
      vsn = options[:vsn]
      sref = options[:sref]


      entity = cond do
                 options[:for_repo] ->
                  entity = Module.concat(Enum.slice(Module.split(__MODULE__), 0..-2) ++ [Entity])
                   Module.put_attribute(__MODULE__, :__nzdo__entity, entity)
                   Module.put_attribute(__MODULE__, :__nzdo__struct, entity)
                 :else ->
                   Module.put_attribute(__MODULE__, :__nzdo__entity, __MODULE__)
                   Module.put_attribute(__MODULE__, :__nzdo__struct, __MODULE__)
               end

      @__nzdo__schema_helper noizu_domain_object_schema || raise "#{
        __MODULE__
      } you must pass in noizu_domain_object_schema or set {:noizu_scaffolding, :domain_object_schema} config value."
      @__nzdo__poly_base (cond do
                            v = poly_base -> v
                            v = Module.get_attribute(__MODULE__, :poly_base) -> v
                            !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(:poly_base) -> @__nzdo__base.__noizu_info__(:poly_base)
                            @__nzdo__base_open? -> (Module.get_attribute(@__nzdo__base, :poly_base) || @__nzdo__base)
                            :else -> @__nzdo__base
                          end)
      @__nzdo__poly_base_open? Module.open?(@__nzdo__poly_base)
      @__nzdo__poly_support (cond do
                                poly_support -> poly_support
                                v = Module.get_attribute(__MODULE__, :poly_support) -> v
                                v = @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, :poly_support) -> v
                                v = !@__nzdo__base_open? && @__nzdo__base.__noizu_info__(:poly)[:support] -> v
                                v = @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, :poly_support) -> v
                                v = !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info__(:poly)[:support] -> v
                                :else -> nil
                              end)
      @__nzdo__poly? ((@__nzdo__poly_base != @__nzdo__base || @__nzdo__poly_support) && true || false)
      @__nzdo__repo repo || Noizu.DomainObject.extract_attribute(:repo, Module.concat([@__nzdo__poly_base, "Repo"]))
      @__nzdo__sref sref || Noizu.DomainObject.extract_attribute(:sref, :unsupported)
      @vsn vsn || Noizu.DomainObject.extract_attribute(:vsn, 1.0)

      if @__nzdo__base_open? && !options[:for_repo] do
        Module.put_attribute(@__nzdo__base, :__nzdo__sref, @__nzdo__sref)
        Module.put_attribute(@__nzdo__base, :__nzdo__entity, __MODULE__)
        Module.put_attribute(@__nzdo__base, :__nzdo__struct, __MODULE__)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly_support, @__nzdo__poly_support)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly?, @__nzdo__poly?)
        Module.put_attribute(@__nzdo__base, :__nzdo__poly_base, @__nzdo__poly_base)
        Module.put_attribute(@__nzdo__base, :vsn, @vsn)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__sphinx__macro__
  #----------------------------------------------------
  defmacro __prepare__sphinx__macro__(options) do
    quote do
      options = unquote(options)

      #----------------------
      # Load Sphinx Settings from base.
      #----------------------
      @__nzdo__indexes Noizu.DomainObject.extract_transform_attribute(:index, :indexing, {Noizu.DomainObject, :expand_indexes, [@__nzdo__base]}, [])
      @__nzdo__index_list Enum.map(@__nzdo__indexes, fn ({k, _v}) -> k end)
      @__nzdo__inline_index Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index.domain_object_indexer(@__nzdo__base)

      if (@__nzdo__base_open? && !options[:for_repo]) do
        Module.put_attribute(@__nzdo__base, :__nzdo__indexes, @__nzdo__indexes)
        Module.put_attribute(@__nzdo__base, :__nzdo__index_list, @__nzdo__index_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__inline_index, @__nzdo__inline_index)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__persistence_settings__macro__
  #----------------------------------------------------
  defmacro __prepare__persistence_settings__macro__(options) do
    enum_list = options[:enum_list]
    quote do
      options = unquote(options)

      a__nzdo__auto_generate = Noizu.DomainObject.extract_has_persistence_attribute(:auto_generate, nil)
      a__nzdo__enum_list = unquote(enum_list) || Noizu.DomainObject.extract_has_enum_attribute(:enum_list, :list, false)
      a__nzdo__enum_default_value  = Noizu.DomainObject.extract_has_enum_attribute(:default_value, :default, :none)
      a__nzdo__enum_ecto_type = Noizu.DomainObject.extract_has_enum_attribute(:ecto_type, :value_type, :integer)

      @__nzdo__auto_generate a__nzdo__auto_generate
      @__nzdo__enum_list a__nzdo__enum_list
      @__nzdo__enum_default_value a__nzdo__enum_default_value
      @__nzdo__enum_ecto_type a__nzdo__enum_ecto_type

      case Noizu.DomainObject.extract_has_attribute(:universal_identifier, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :universal_identifier, v)
      end

      case Noizu.DomainObject.extract_has_attribute(:generate_reference_type, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :generate_reference_type, v)
      end

      case Noizu.DomainObject.extract_has_attribute(:universal_lookup, :not_set) do
        :not_set -> :skip
        v -> Module.put_attribute(__MODULE__, :universal_lookup, v)
      end

      a__nzdo_persistence = Noizu.DomainObject.extract_transform_attribute(:persistence_layer, :persistence, {Noizu.DomainObject, :expand_persistence_layers, [__MODULE__]})
      @__nzdo_persistence a__nzdo_persistence
      a__nzdo_persistence__layers = Enum.map(a__nzdo_persistence.layers, fn (layer) -> {layer.schema, layer} end)
                                  |> Map.new()
      @__nzdo_persistence__layers a__nzdo_persistence__layers
      a__nzdo_persistence__by_table = Enum.map(a__nzdo_persistence.layers, fn (layer) -> {layer.table, layer} end)
                                    |> Map.new()
      @__nzdo_persistence__by_table a__nzdo_persistence__by_table

      a__nzdo_ecto_entity = (a__nzdo_persistence.ecto_entity && true || false)
      @__nzdo_ecto_entity a__nzdo_ecto_entity



      if @__nzdo_ecto_entity do
        @__nzdo__derive Noizu.Ecto.Entity
      end

      if (@__nzdo__base_open?) do
        Module.put_attribute(@__nzdo__base, :__nzdo__auto_generate, a__nzdo__auto_generate)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_list, a__nzdo__enum_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_table, a__nzdo_persistence.options.enum_table)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_default_value, a__nzdo__enum_default_value)
        Module.put_attribute(@__nzdo__base, :__nzdo__enum_ecto_type, a__nzdo__enum_ecto_type)

        Module.put_attribute(@__nzdo__base, :__nzdo_persistence, a__nzdo_persistence)
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence__layers, a__nzdo_persistence__layers)
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence__by_table, a__nzdo_persistence__by_table)
        Module.put_attribute(@__nzdo__base, :__nzdo_ecto_entity, a__nzdo_ecto_entity)
      end
    end
  end


  #----------------------------------------------------
  # __prepare__nmid__macro__
  #----------------------------------------------------
  defmacro __prepare__nmid__macro__(_) do
    default_nmid_generator = Application.get_env(:noizu_scaffolding, :default_nmid_generator, Noizu.Scaffolding.V3.NmidGenerator)
    quote do
      @__nzdo__nmid_generator Noizu.DomainObject.extract_has_nmid_attribute(:nmid_generator, :generator, unquote(default_nmid_generator))
      @__nzdo__nmid_sequencer Noizu.DomainObject.extract_has_nmid_attribute(:nmid_sequencer, :sequencer, __MODULE__)
      @__nzdo__nmid_index Noizu.DomainObject.extract_has_nmid_attribute(:nmid_index, :index, nil)
      @__nzdo__nmid_bare Noizu.DomainObject.extract_has_nmid_attribute(:nmid_bare, :bare,  @__nzdo_persistence.options[:enum_table] && true || false)

      if (@__nzdo__base_open?) do
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_generator, @__nzdo__nmid_generator)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_sequencer, @__nzdo__nmid_sequencer)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_index, @__nzdo__nmid_index)
        Module.put_attribute(@__nzdo__base, :__nzdo__nmid_bare, @__nzdo__nmid_bare)
      end
    end
  end

  #----------------------------------------------------
  # __prepare__json_settings__macro__
  #----------------------------------------------------
  defmacro __prepare__json_settings__macro__(options) do
    quote do
      options = unquote(options)
      json_provider = options[:json_provider]
      json_format = options[:json_format]
      json_white_list = options[:json_white_list]
      json_supported_formats = options[:json_supported_formats]

      @__nzdo__json_provider json_provider || Noizu.DomainObject.extract_json_attribute(:json_provider, :provider, Noizu.Scaffolding.V3.Poison.Encoder)
      @__nzdo__json_format json_format || Noizu.DomainObject.extract_has_json_attribute(:json_format, :default, :default)
      @__nzdo__json_supported_formats json_supported_formats || Noizu.DomainObject.extract_has_json_attribute(
        :json_supported_formats, :formats,
        [:standard, :admin, :verbose, :compact, :mobile, :verbose_mobile]
      )
      @__nzdo__json_format_groups (
                                    Enum.map(
                                      Noizu.DomainObject.extract_json_attribute(:json_format_group, :format_groups, []),
                                      fn (group) ->
                                        case group do
                                          {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                          {alias, members} when is_list(members) -> {alias, [members: members]}
                                          {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                          {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                          _ -> raise "Invalid @json_formatting_group entry #{inspect group}"
                                        end
                                      end
                                    )
                                    |> Map.new())
      @__nzdo__json_field_groups (
                                   Enum.map(
                                     Noizu.DomainObject.extract_json_attribute(:json_field_group, :field_groups, []),
                                     fn (group) ->
                                       case group do
                                         {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                         {alias, members} when is_list(members) -> {alias, [members: members]}
                                         {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                         {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                         _ -> raise "Invalid @json_field_group entry #{inspect group}"
                                       end
                                     end
                                   )
                                   |> Map.new())
      @__nzdo__json_white_list (cond do
                                  json_white_list -> json_white_list
                                  :else -> Noizu.DomainObject.extract_has_json_attribute(:json_white_list, :white_list, false)
                                end)

      __nzdo__json_config = %{
        provider: @__nzdo__json_provider,
        defualt_format: @__nzdo__json_format,
        white_list: @__nzdo__json_white_list,
        selection_groups: @__nzdo__json_format_groups,
        field_groups: @__nzdo__json_field_groups,
        supported: @__nzdo__json_supported_formats
      }
      Module.put_attribute(__MODULE__, :__nzdo__json_config, __nzdo__json_config)

      if (@__nzdo__base_open? && !options[:for_repo]) do
        Module.put_attribute(@__nzdo__base, :__nzdo__json_provider, @__nzdo__json_provider)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_format, @__nzdo__json_format)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_supported_formats, @__nzdo__json_supported_formats)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_format_groups, @__nzdo__json_format_groups)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_field_groups, @__nzdo__json_field_groups)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_white_list, @__nzdo__json_white_list)
        Module.put_attribute(@__nzdo__base, :__nzdo__json_config, @__nzdo__json_config)
      end
    end
  end


end
