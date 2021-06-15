#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity do
  alias Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity, as: EntityMeta

  #--------------------------
  #
  #--------------------------
  defmacro identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, :identifier, unquote(opts))
      EntityMeta.__identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __identifier__(mod, type, _opts) do
    Module.put_attribute(mod, :__nzdo__identifier_type, type)
    __public_field__(mod, :identifier, nil, [])
  end


  #--------------------------
  #
  #--------------------------
  defmacro ecto_identifier(type \\ :integer, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, :ecto_identifier, unquote(opts))
      EntityMeta.__ecto_identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  def __ecto_identifier__(mod, _type, _opts) do
    Module.put_attribute(mod, :__nzdo__ecto_identifier_field, true)
    __public_field__(mod, :ecto_identifier, nil, [])
  end

  #--------------------------
  #
  #--------------------------
  defmacro public_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__public_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __public_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :public})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro public_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__public_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __public_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __public_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  defmacro restricted_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__restricted_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __restricted_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :restricted})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro restricted_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__restricted_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __restricted_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __restricted_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__private_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __private_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :private})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro private_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__private_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __private_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __private_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_field(field, default \\ nil, opts \\ []) do
    quote do
      EntityMeta.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      EntityMeta.__internal_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  def __internal_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :internal})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  #--------------------------
  #
  #--------------------------
  defmacro internal_fields(fields, opts \\ []) do
    quote do
      EntityMeta.__internal_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end
  def __internal_fields__(mod, fields, default, opts) do
    Enum.map(fields, fn(field) ->
      __internal_field__(mod, field, default, opts)
    end)
  end

  #--------------------------
  #
  #--------------------------
  def __set_field_attributes__(mod, field, opts) do
    cond do
      nil == opts -> :ok
      [] == opts -> :ok
      is_atom(opts) -> Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: opts}})
      (is_list(opts) || is_map(opts)) && opts[:type] ->
        Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: opts[:type]}})
      :else -> :ok
    end

    EntityMeta.__set_json_settings__(mod, field, opts)

    options = %{}
    options = cond do
                (Module.has_attribute?(mod, :pii)) ->
                  o = put_in(options, [:pii], Module.get_attribute(mod, :pii))
                  Module.delete_attribute(mod, :pii)
                  o
                :else -> options
              end

    if options != %{} do
      Module.put_attribute(mod, :__nzdo__field_attributes, {field, options})
    end
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_json_settings__(mod, field, opts) do
    config = Module.get_attribute(mod, :__nzdo__json_config)
    settings = Module.get_attribute(mod, :__nzdo__raw__json_format_settings, %{})
               |>     EntityMeta.__extract_json_settings__(:json, mod, field, config, opts)
               |>     EntityMeta.__extract_json_settings__(:json_embed, mod, field, config, opts)
               |>     EntityMeta.__extract_json_settings__(:json_ignore, mod, field, config, opts)
    Module.put_attribute(mod, :__nzdo__raw__json_format_settings, settings)
  end


  # Selector Expansion
  # :* -> set of all supported formats from config map -> [list]
  # :alias (is supported or a predefined json_formatting group -> [list]
  # [aliases] -> set of format groups or formants flatten to bigger list
  # rules override in sequence however the different tags are processe3d in a different order
  # json < json_embed < json_ignore

  # include flag if not specified defaults to global settings (White list or black list, or white_list with set, or black list with set)

  # output_data structure
  # %{
  #    mobile: %{
  #                expand?: true | false,
  #                embed: nil | [rules]
  #                format: {format, Keyword.T}
  #                include: true | false, # if false don't include output

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_entry__({selector, settings}, field, config, opts) do
    selector = __expand_json_selector__(selector, config, opts)
    fields = __expand_json_field__(field, config, opts)
    settings = cond do
                 is_list(settings) -> settings
                 :else -> [settings]
               end
    {selector, fields, settings}
  end
  def __expand_json_entry__({selector, fields, settings}, _field, config, opts) do
    selector = __expand_json_selector__(selector, config, opts)
    fields = __expand_json_field__(fields, config, opts)
    settings = cond do
                 is_list(settings) -> settings
                 :else -> [settings]
               end
    {selector, fields, settings}
  end

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_selector__(:*, config, _opts) do
    config.supported
  end

  def __expand_json_selector__(selector, config, _opts) when is_atom(selector) do
    cond do
      g = config.selection_groups[selector][:members] -> g
      :else -> [selector]
    end
  end

  def __expand_json_selector__(selectors, config, opts) when is_list(selectors) do
    Enum.map(selectors,
      fn(selector) ->
        __expand_json_selector__(selector, config, opts)
      end)
    |> List.flatten()
    |> Enum.uniq()
  end

  #---------------------------------
  #
  #---------------------------------
  def __expand_json_field__(field, config, _opts) when is_atom(field) do
    cond do
      g = config.field_groups[field][:members] -> g
      :else -> [field]
    end
  end

  def __expand_json_field__(fields, config, opts) when is_list(fields) do
    Enum.map(fields,
      fn(field) ->
        __expand_json_field__(field, config, opts)
      end)
    |> List.flatten()
    |> Enum.uniq()
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    # {selector, fields, ...}
    # {selector, expand}
    # {selector, format: _}
    # {[selectors], ..}
    # {selector, as: "RenameTo"}
    # {selector, embed: [list]}
    Enum.reduce(entries || [], acc, fn(entry, acc) ->
      {selectors, fields, settings} = __expand_json_entry__(entry, field, config, opts)
      Enum.reduce(settings, acc,
        fn(s, acc) ->
          case s do
            :expand -> __set_option__(acc, selectors, fields, {:expand, true})
            :sref -> __set_option__(acc, selectors, fields, {:sref, true})
            :ignore -> __set_option__(acc, selectors, fields, {:include, false})
            :include -> __set_option__(acc, selectors, fields, {:include, true})
            {:format, _} -> __set_option__(acc, selectors, fields, s)
            {:as, _} -> __set_option__(acc, selectors, fields, s)
            {:embed, embed} when is_atom(embed)->
              embed = Map.new([{:embed, true}])
              __set_option__(acc, selectors, fields, {:embed, embed})
            {:embed, embed} when is_list(embed)->
              embed = Enum.map(embed, fn(e) ->
                 case e do
                   e when is_atom(e) -> {e, true}
                   {e, f} -> {e, f}
                   _ -> nil
                 end
              end) |> Enum.filter(&(&1)) |> Map.new()
              __set_option__(acc, selectors, fields, {:embed, embed})
            _ -> acc
          end
        end
      )
    end)
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_embed, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(entries, acc, fn(entry, acc) ->
      case entry do
        {selector, embed} when is_list(embed) ->
          selectors = __expand_json_selector__(selector, config, opts)
          embed = Enum.map(embed, fn(e) ->
            case e do
              e when is_atom(e) -> {e, true}
              {e, f} -> {e, f}
              _ -> nil
            end
          end) |> Enum.filter(&(&1)) |> Map.new()
          __set_option__(acc, selectors, [field], {:embed, embed})
        {selector, embed} when is_atom(embed) ->
          selectors = __expand_json_selector__(selector, config, opts)
          embed = Map.new([{:embed, true}])
          __set_option__(acc, selectors, [field], {:embed, embed})
        _ -> acc
      end
    end)
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_ignore, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(entries, acc, fn(entry, acc) ->
      case entry do
        {selector, fields} ->
          selectors = __expand_json_selector__(selector, config, opts)
          fields = __expand_json_field__(fields, config, opts)
          __set_option__(acc, selectors, fields, {:include, false})
        selector ->
          selectors = __expand_json_selector__(selector, config, opts)
          __set_option__(acc, selectors, [field], {:include, false})
      end
    end)
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_option__(acc, formats, fields, {setting, setting_value}) do
    Enum.reduce(formats, acc, fn(format, acc) ->
      acc = update_in(acc, [format], &(&1 || %{}))
      Enum.reduce(fields, acc, fn(field, acc) ->
        acc = update_in(acc, [format, field], &(&1 || %{}))
        put_in(acc, [format, field, setting], setting_value)
      end)
    end)
  end



  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_entity__(caller, options, block) do
    erp_provider = options[:erp_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider
    ecto_provider = options[:ecto_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider
    base = options[:domain_object]
    repo = options[:repo]
    vsn = options[:vsn]
    sref = options[:sref]
    default_nmid_generator = Application.get_env(:noizu_scaffolding, :default_nmid_generator, Noizu.Scaffolding.V3.NmidGenerator)
    poly_base = options[:poly_base]
    poly_support = options[:poly_support]
    json_provider = options[:json_provider]
    json_format = options[:json_format]
    json_white_list = options[:json_white_list]
    json_supported_formats = options[:json_supported_formats]
    noizu_domain_object_schema = options[:noizu_domain_object_schema] || Application.get_env(:noizu_scaffolding, :domain_object_schema)
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__entity_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_entity first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end
                       @__nzdo__entity_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @__nzdo__base unquote(base) || Module.get_attribute(__MODULE__, :domain_object) || (Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat())
                       @__nzdo__base_open? Module.open?(@__nzdo__base)
                       if !@__nzdo__base_open? && !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

                       #---------------------
                       # Registerss
                       #---------------------
                       Module.register_attribute(__MODULE__, :meta, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__fields, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
                       Module.register_attribute(__MODULE__, :__nzdo__field_permissions, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_types, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_attributes, accumulate: true)


                       #Json Encoding Instructions
                       Module.register_attribute(__MODULE__, :json, accumulate: true)
                       Module.register_attribute(__MODULE__, :json_embed, accumulate: true)
                       Module.register_attribute(__MODULE__, :json_ignore, accumulate: true)
                       Module.register_attribute(__MODULE__, :json_restrict, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__raw__json_format_settings, accumulate: false)
                       Module.put_attribute(__MODULE__, :__nzdo__raw__json_format_settings, %{})

                       #---------------------
                       # Push details to Base, and read in required settings.
                       #---------------------
                       @__nzdo__schema_helper unquote(noizu_domain_object_schema) || raise "#{__MODULE__} you must pass in noizu_domain_object_schema or set {:noizu_scaffolding, :domain_object_schema} config value."

                       @__nzdo__poly_base (cond do
                                             v = unquote(poly_base) -> v
                                             v = Module.get_attribute(__MODULE__, :poly_base) -> v
                                             !@__nzdo__base_open? && @__nzdo__base.__noizu_info(:poly_base) -> @__nzdo__base.__noizu_info(:poly_base)
                                             @__nzdo__base_open? -> (Module.get_attribute(@__nzdo__base, :poly_base) || @__nzdo__base)
                                             :else -> @__nzdo__base
                                           end)
                       @__nzdo__poly_base_open? Module.open?(@__nzdo__poly_base)
                       @__nzdo__poly_support unquote(poly_support) || Noizu.DomainObject.extract_attribute(:poly_support, nil)
                       @__nzdo__poly? ((@__nzdo__poly_base != @__nzdo__base || @__nzdo__poly_support) && true || false)
                       @__nzdo__repo unquote(repo) || Noizu.DomainObject.extract_attribute(:repo, Module.concat([@__nzdo__poly_base, "Repo"]))
                       @__nzdo__sref unquote(sref) || Noizu.DomainObject.extract_attribute(:sref, :unsupported)
                       @vsn unquote(vsn) || Noizu.DomainObject.extract_attribute(:vsn, 1.0)

                       if @__nzdo__base_open? do
                         Module.put_attribute(@__nzdo__base, :__nzdo__sref, @__nzdo__sref)
                         Module.put_attribute(@__nzdo__base, :__nzdo__entity, __MODULE__)
                         Module.put_attribute(@__nzdo__base, :__nzdo__poly_support, @__nzdo__poly_support)
                         Module.put_attribute(@__nzdo__base, :__nzdo__poly?, @__nzdo__poly?)
                         Module.put_attribute(@__nzdo__base, :__nzdo__poly_base, @__nzdo__poly_base)
                         Module.put_attribute(@__nzdo__base, :vsn, @vsn)
                       end

                       #----------------------
                       # Always hook into Noizu.ERP
                       #----------------------
                       @__nzdo__derive Noizu.ERP
                       @__nzdo__derive Noizu.V3.EntityProtocol

                       #----------------------
                       # Load Persistence Settings from base, we need them to control some submodules.
                       #----------------------
                       @__nzdo__auto_generate Noizu.DomainObject.extract_has_attribute(:auto_generate, nil)
                       @__nzdo__enum_list Noizu.DomainObject.extract_has_attribute(:enum_list, false)
                       @__nzdo__enum_default_value Noizu.DomainObject.extract_has_attribute(:default_value, :none)
                       @__nzdo__enum_ecto_type Noizu.DomainObject.extract_has_attribute(:ecto_type, :integer)

                       @__nzdo_persistence Noizu.DomainObject.extract_transform_attribute(:persistence_layer, :persistence, {Noizu.DomainObject, :expand_persistence_layers, [__MODULE__]})
                       @__nzdo_persistence__layers Enum.map(@__nzdo_persistence.layers, fn(layer) -> {layer.schema, layer} end) |> Map.new()
                       @__nzdo_persistence__by_table Enum.map(@__nzdo_persistence.layers, fn(layer) -> {layer.table, layer} end) |> Map.new()
                       @__nzdo_ecto_entity (@__nzdo_persistence.ecto_entity && true || false)
                       if @__nzdo_ecto_entity do
                         @derive_list Noizu.Ecto.Entity
                       end


                       if @__nzdo__base_open? do
                         Module.put_attribute(@__nzdo__base, :__nzdo_persistence, @__nzdo_persistence)
                         Module.put_attribute(@__nzdo__base, :__nzdo__enum_list, @__nzdo__enum_list)
                         Module.put_attribute(@__nzdo__base, :__nzdo__enum_default_value, @__nzdo__enum_default_value)
                         Module.put_attribute(@__nzdo__base, :__nzdo__enum_ecto_type, @__nzdo__enum_ecto_type)
                       end


                       #--------------------------------
                       # Nmid
                       #--------------------------------
                       @__nzdo__nmid_generator Noizu.DomainObject.extract_has_attribute(:nmid_generator, unquote(default_nmid_generator))
                       @__nzdo__nmid_sequencer Noizu.DomainObject.extract_has_attribute(:nmid_sequencer, __MODULE__)
                       @__nzdo__nmid_index Noizu.DomainObject.extract_has_attribute(:nmid_index, nil)
                       @__nzdo__nmid_bare Noizu.DomainObject.extract_has_attribute(:nmid_bare, @__nzdo_persistence.options[:enum_table] && true || false)
                       if @__nzdo__base_open? do
                         Module.put_attribute(@__nzdo__base, :__nzdo__nmid_generator, @__nzdo__nmid_generator)
                         Module.put_attribute(@__nzdo__base, :__nzdo__nmid_sequencer, @__nzdo__nmid_sequencer)
                         Module.put_attribute(@__nzdo__base, :__nzdo__nmid_index, @__nzdo__nmid_index)
                         Module.put_attribute(@__nzdo__base, :__nzdo__nmid_bare, @__nzdo__nmid_bare)
                       end


                       #--------------------------------
                       # Json Settings
                       #--------------------------------
                       @__nzdo__json_provider unquote(json_provider) || Noizu.DomainObject.extract_attribute(:json_provider, Noizu.Scaffolding.V3.Poison.Encoder)
                       @__nzdo__json_format unquote(json_format) || Noizu.DomainObject.extract_has_attribute(:json_format, :default)
                       @__nzdo__json_supported_formats unquote(json_supported_formats) || Noizu.DomainObject.extract_has_attribute(:json_supported_formats,  [:standard, :admin, :verbose, :compact, :mobile, :verbose_mobile])
                       @__nzdo__json_format_groups (Enum.map(Noizu.DomainObject.extract_attribute(:json_format_group, []),
                                                      fn(group) ->
                                                        case group do
                                                          {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                                          {alias, members} when is_list(members) -> {alias, [members: members]}
                                                          {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                                          {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                                          _ -> raise "Invalid @json_formatting_group entry #{inspect group}"
                                                        end
                                                      end) |> Map.new())
                       @__nzdo__json_field_groups (Enum.map(Noizu.DomainObject.extract_attribute(:json_field_group, []),
                                                     fn(group) ->
                                                       case group do
                                                         {alias, member} when is_atom(member) -> {alias, [members: [member]]}
                                                         {alias, members} when is_list(members) -> {alias, [members: members]}
                                                         {alias, member, defaults} when is_atom(member) -> {alias, [members: [member], defaults: defaults]}
                                                         {alias, members, defaults} when is_list(members) -> {alias, [members: members, defaults: defaults]}
                                                         _ -> raise "Invalid @json_field_group entry #{inspect group}"
                                                       end
                                                     end) |> Map.new())
                       @__nzdo__json_white_list (cond do
                                                   unquote(json_white_list) != nil -> unquote(json_white_list)
                                                   :else -> Noizu.DomainObject.extract_has_attribute(:json_white_list, false)
                                                 end)
                       if (@__nzdo__base_open?) do
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_provider, @__nzdo__json_provider)
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_format, @__nzdo__json_format)
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_supported_formats, @__nzdo__json_supported_formats)
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_format_groups, @__nzdo__json_format_groups)
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_field_groups, @__nzdo__json_field_groups)
                         Module.put_attribute(@__nzdo__base, :__nzdo__json_white_list, @__nzdo__json_white_list)
                       end

                       #----------------------
                       #
                       #----------------------
                       __nzdo__json_config = %{
                         provider: @__nzdo__json_provider,
                         defualt_format: @__nzdo__json_format,
                         white_list: @__nzdo__json_white_list,
                         selection_groups: @__nzdo__json_format_groups,
                         field_groups: @__nzdo__json_field_groups,
                         supported: @__nzdo__json_supported_formats
                       }
                       Module.put_attribute(__MODULE__, :__nzdo__json_config, __nzdo__json_config)

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         unquote(block)
                       after
                         :ok
                       end

                       # Set Meta
                       base_meta = Module.has_attribute?(@__nzdo__base, :meta) && Module.get_attribute(@__nzdo__base, :meta) || []
                       meta =  (base_meta) ++ (Module.has_attribute?(__MODULE__, :meta) && Module.get_attribute(__MODULE__, :meta) || [])
                       Module.put_attribute(@__nzdo__base, :__nzdo__meta, meta)

                       #----------------------
                       # fields meta data
                       #----------------------
                       @__nzdo__field_types_map ((@__nzdo__field_types || []) |> Map.new())
                       @__nzdo__field_list (Enum.map(@__nzdo__fields, fn({k,_}) -> k end) -- [:initial, :meta])

                       #----------------------
                       # Universals Fields (always include)
                       #----------------------
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:initial, nil})
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:meta, %{}})
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:vsn, @vsn})
                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields

                 if (@__nzdo__json_provider) do
                   __nzdo__json_provider = @__nzdo__json_provider
                   defimpl Poison.Encoder  do
                     defdelegate encode(entity, options \\ nil), to: __nzdo__json_provider
                   end
                 end


               end

    quote do
      unquote(process_config)
      unquote(generate)
      use unquote(erp_provider)
      use unquote(ecto_provider)

      # Post User Logic Hook and checks.
      @before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
      @after_compile unquote(internal_provider)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    quote do
      defdelegate vsn(), to: @__nzdo__base
      def __entity__(), do: __MODULE__
      def __base__(), do: @__nzdo__base
      defdelegate __repo__(), to: @__nzdo__base
      defdelegate __sref__(), to: @__nzdo__base
      defdelegate __erp__(), to: @__nzdo__base

      @__nzdo_associated_types (Enum.map(@__nzdo_persistence__by_table || %{}, fn({k,v}) -> {k, v.type} end) ++ Enum.map(@__nzdo__poly_support || %{}, fn(k,v) -> {k, :poly} end) ) |> Map.new()
      @__nzdo__json_config put_in(@__nzdo__json_config, [:format_settings], @__nzdo__raw__json_format_settings)
      @__nzdo__field_attributes_map Map.new(@__nzdo__field_attributes)

      @__nzdo_persistence Noizu.Scaffolding.V3.Schema.PersistenceSettings.update_schema_fields(@__nzdo_persistence, @__nzdo__field_types_map)
      if @__nzdo__base_open? do
        Module.put_attribute(@__nzdo__base, :__nzdo_persistence, @__nzdo_persistence)
      end

      def __persistence__(), do: __persistence__(:all)
      def __persistence__(:all), do:  @__nzdo_persistence
      def __persistence__(:enum_table), do:  @__nzdo_persistence.options.enum_table
      def __persistence__(:auto_generate), do:  @__nzdo_persistence.options.auto_generate
      def __persistence__(:universal_identifier), do:  @__nzdo_persistence.options.universal_identifier
      def __persistence__(:universal_lookup), do:  @__nzdo_persistence.options.universal_lookup
      def __persistence__(:reference_type), do:  @__nzdo_persistence.options.generate_reference_type
      def __persistence__(:layer), do:  @__nzdo_persistence.layers
      def __persistence__(:schema), do:  @__nzdo_persistence.schemas
      def __persistence__(:table), do:  @__nzdo_persistence.tables
      def __persistence__(:ecto_entity), do:  @__nzdo_persistence.ecto_entity
      def __persistence__(:options), do:  @__nzdo_persistence.options
      def __persistence__(repo, :table), do:  @__nzdo_persistence.schemas[repo] && @__nzdo_persistence.schemas[repo].table

      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all) do
        %{
          generator:  __nmid__(:generator),
          sequencer: __nmid__(:sequencer),
          bare: __nmid__(:bare),
          index: __nmid__(:index),
        }
      end
      def __nmid__(:index), do: @__nzdo__nmid_index || @__nzdo__schema_helper.__noizu_info__(:nmid_indexes)[__MODULE__]
      defdelegate __nmid__(setting), to: @__nzdo__base


      def __noizu_info__(:type), do: :entity
      def __noizu_info__(:identifier_type), do: @__nzdo__identifier_type
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: @__nzdo_persistence
      def __noizu_info__(:tables), do: @__nzdo_persistence__by_table
      def __noizu_info__(:associated_types), do: @__nzdo_associated_types
      def __noizu_info__(:json_configuration), do: @__nzdo__json_config
      def __noizu_info__(:field_attributes), do: @__nzdo__field_attributes_map

      defdelegate __noizu_info__(report), to: @__nzdo__base

    end
  end
end
