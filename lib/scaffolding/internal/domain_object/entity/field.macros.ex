defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros do
  alias Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros, as: FieldMacros

  #==================================================
  # Macros
  #==================================================

  #--------------------------
  # identifier
  #--------------------------
  @doc """
  Declare DomainObject.Entity identifier field type.
  """
  defmacro identifier(type \\ :integer, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, :identifier, unquote(opts))
      FieldMacros.__identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  #--------------------------
  # ecto_identifier
  #--------------------------
  @doc """
  Declare DomainObject.Entity ecto/universal identifier, for entities that do not use a sequential numeric identifier but need read/write to ecto as well as mnesia.
  """
  defmacro ecto_identifier(type \\ :integer, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, :ecto_identifier, unquote(opts))
      FieldMacros.__ecto_identifier__(__MODULE__, unquote(type), unquote(opts))
    end
  end

  #--------------------------
  # public_field
  #--------------------------
  defmacro public_field(field, default \\ nil, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      FieldMacros.__public_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  #--------------------------
  # public_fields
  #--------------------------
  defmacro public_fields(fields, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__public_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end

  #--------------------------
  # restricted_field
  #--------------------------
  defmacro restricted_field(field, default \\ nil, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      FieldMacros.__restricted_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  #--------------------------
  # restricted_fields
  #--------------------------
  defmacro restricted_fields(fields, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__restricted_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end

  #--------------------------
  # private_field
  #--------------------------
  defmacro private_field(field, default \\ nil, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      FieldMacros.__private_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  #--------------------------
  #  private_fields
  #--------------------------
  defmacro private_fields(fields, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__private_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end

  #--------------------------
  # internal_field
  #--------------------------
  defmacro internal_field(field, default \\ nil, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      FieldMacros.__internal_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  #--------------------------
  # internal_fields
  #--------------------------
  defmacro internal_fields(fields, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__internal_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end

  #--------------------------
  #
  #--------------------------
  defmacro transient_field(field, default \\ nil, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__set_field_attributes__(__MODULE__, unquote(field), unquote(opts))
      FieldMacros.__transient_field__(__MODULE__, unquote(field), unquote(default), unquote(opts))
    end
  end

  #--------------------------
  # transient_fields
  #--------------------------
  defmacro transient_fields(fields, opts \\ []) do
    opts = Macro.expand(opts, __ENV__)
    quote do
      FieldMacros.__transient_fields__(__MODULE__, unquote(fields), unquote(opts[:default] || nil), unquote(opts))
    end
  end



  #==================================================
  # Support
  #==================================================

  def __identifier__(mod, type, _opts) do
    Module.put_attribute(mod, :__nzdo__identifier_type, type)
    __public_field__(mod, :identifier, nil, [])
  end

  def __ecto_identifier__(mod, _type, _opts) do
    Module.put_attribute(mod, :__nzdo__ecto_identifier_field, true)
    __public_field__(mod, :ecto_identifier, nil, [])
  end

  def __public_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :public})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  def __public_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __public_field__(mod, field, default, opts)
      end
    )
  end

  def __restricted_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :restricted})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  def __restricted_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __restricted_field__(mod, field, default, opts)
      end
    )
  end

  def __private_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :private})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  def __private_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __private_field__(mod, field, default, opts)
      end
    )
  end

  def __internal_field__(mod, field, default, _opts) do
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :internal})
    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  def __internal_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __internal_field__(mod, field, default, opts)
      end
    )
  end

  def __transient_field__(mod, field, default, _opts) do
    # Field which is not persisted to main mnesia record but may be loaded into object for end user convienence
    Module.put_attribute(mod, :__nzdo__field_permissions, {field, :restricted})
    Module.put_attribute(mod, :__nzdo__field_attributes, {field, [transient: true]})

    Module.put_attribute(mod, :__nzdo__fields, {field, default})
  end

  def __transient_fields__(mod, fields, default, opts) do
    Enum.map(
      fields,
      fn (field) ->
        __transient_field__(mod, field, default, opts)
      end
    )
  end

  #--------------------------
  #
  #--------------------------
  def pii_level(value) do
    levels = %{
      0 => :level_0,
      1 => :level_1,
      2 => :level_2,
      3 => :level_3,
      4 => :level_4,
      5 => :level_5,
      6 => :level_6,
      :level_0 => :level_0,
      :level_1 => :level_1,
      :level_2 => :level_2,
      :level_3 => :level_3,
      :level_4 => :level_4,
      :level_5 => :level_5,
      :level_6 => :level_6,

      true => :level_3,
      false => :level_6,
      :default => :level_6,
    }
    levels[value] || levels[:default]
  end


  def __field_attribute_normalize__(:inspect, attr_value), do: attr_value
  def __field_attribute_normalize__(:pii, attr_value), do: FieldMacros.pii_level(attr_value)
  def __field_attribute_normalize__(:required, attr_value) do
    case attr_value do
      [ref: v] -> {:ref, __field_attribute_normalize__(:ref, v)}
      [enum: v] -> {:enum, __field_attribute_normalize__(:enum, v)}
      [struct: v] -> {:struct, __field_attribute_normalize__(:struct, v)}
      {:ref, v} -> {:ref, __field_attribute_normalize__(:ref, v)}
      {:enum, v} -> {:enum, __field_attribute_normalize__(:enum, v)}
      {:struct, v} -> {:struct, __field_attribute_normalize__(:struct, v)}
      _else -> attr_value
    end
  end
  def __field_attribute_normalize__(:enum, attr_value) do
    case attr_value do
      true -> :any
      v when is_list(v) -> List.flatten(v)
      v when is_atom(v) -> v
    end
  end
  def __field_attribute_normalize__(type, attr_value) when type == :ref or type == :struct do
    case attr_value do
      true -> :any
      v when is_list(v) -> MapSet.new(List.flatten(v))
      v when is_atom(v) -> MapSet.new([v])
    end
  end



  def __field_attribute_valid__?(:inspect, _attr_value), do: true
  def __field_attribute_valid__?(:pii, attr_value) do

    cond do
      is_integer(attr_value) && attr_value >= 0 && attr_value <= 6 -> true
      Enum.member?([:level_0, :level_1, :level_2, :level_3, :level_4, :level_5, :level_6], attr_value) -> true
      attr_value == nil -> :ignore
      attr_value == [] -> :ignore
      :else -> false
    end
  end

  def __field_attribute_valid__?(:required, attr_value) do
    case attr_value do
      nil -> :ignore
      true -> true
      false -> true
      {_m, _f} -> true
      {_m, _f, _a} -> true
      f when is_function(f, 1) -> true
      f when is_function(f, 2) -> true
      f when is_function(f, 3) -> true
      f when is_function(f, 4) -> true
      [ref: v] -> __field_attribute_valid__?(:ref, v) && :ref
      [enum: v] -> __field_attribute_valid__?(:enum, v) && :enum
      [struct: v] -> __field_attribute_valid__?(:struct, v) && :struct
      {:ref, v} -> __field_attribute_valid__?(:ref, v) && :ref
      {:enum, v} -> __field_attribute_valid__?(:enum, v) && :enum
      {:struct, v} -> __field_attribute_valid__?(:struct, v) && :struct
      _else -> false
    end
  end
  def __field_attribute_valid__?(type, attr_value) when type == :ref or type == :struct or type == :enum do
    case attr_value do
      nil -> :ignore
      [] -> :ignore
      v when is_list(v) -> true
      v when is_atom(v) -> true
      true -> true
      _ -> false
    end
  end

  def __set_field_attributes__(mod, field, opts) do
    cond do
      nil == opts -> :ok
      [] == opts -> :ok
      is_atom(opts) -> Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: opts}})
      type = (is_list(opts) || is_map(opts)) && opts[:type] ->
        {_, o} = pop_in(opts, [:type])
        cond do
          o == %{}  || o == [] -> Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: type}})
          :else -> Module.put_attribute(mod, :__nzdo__field_types, {field, %{handler: type, options: o}})
        end
      :else -> :ok
    end

    opts = []
    FieldMacros.__set_json_settings__(mod, field, opts)
    FieldMacros.__set_index_settings__(mod, field, opts)
    FieldMacros.__set_permission_settings__(mod, field, opts)

    options = Enum.map(
                [:pii, :ref, :enum, :struct, :required, :inspect],
                fn (attribute) ->
                  cond do
                    Module.has_attribute?(mod, attribute) ->
                      attr_value = Module.get_attribute(mod, attribute)
                      Module.delete_attribute(mod, attribute)
                      valid?  = FieldMacros.__field_attribute_valid__?(attribute, attr_value) || raise "#{mod}.#{field} unsupported @#{attribute} value #{inspect attr_value}}"
                      attr_value = FieldMacros.__field_attribute_normalize__(attribute, attr_value)

                      cond do
                        valid? == :ignore -> nil
                        :else ->
                          case attribute do
                            :inspect -> {:inspect, attr_value}
                            :pii -> {:pii, attr_value}
                            :ref -> {:type_constraint, {:ref, attr_value}}
                            :struct -> {:type_constraint, {:struct, attr_value}}
                            :enum ->
                              case attr_value do
                                :any -> {:type_constraint, {:atom, :any}}
                                v when is_list(v) -> {:type_constraint, {:atom, MapSet.new(v)}}
                                v -> {:type_constraint, {:enum, v}}
                              end
                            :required ->
                              case attr_value do
                                {:ref, v} ->
                                  [{:required, true}, {:type_constraint, {:ref, v}}]
                                {:struct, v} ->
                                  [{:required, true}, {:type_constraint, {:struct, v}}]
                                {:enum, v} ->
                                  type_constraint = case v do
                                                      :any -> {:type_constraint, {:atom, :any}}
                                                      v when is_list(v) -> {:type_constraint, {:atom, MapSet.new(v)}}
                                                      _else -> {:type_constraint, {:enum, v}}
                                                    end
                                  [{:required, true}, type_constraint]
                                _ ->
                                  {:required, attr_value}
                              end
                          end
                      end


                    :else -> nil
                  end
                end
              )
              |> Enum.filter(&(&1))
              |> List.flatten()

    if options != [] do
      Module.put_attribute(mod, :__nzdo__field_attributes, {field, Map.new(options)})
    end
  end


  #---------------------------------
  #
  #---------------------------------
  def __set_index_settings__(mod, field, opts) do
    indexers = Module.get_attribute(mod, :__nzdo__index_list)
    entries = Module.get_attribute(mod, :index)
    Module.delete_attribute(mod, :index)
    o = FieldMacros.__extract_index_settings__(mod, field, indexers, entries, opts)
    o && Module.put_attribute(mod, :__nzdo__field_indexing, o)
  end

  def __extract_index_settings__(_mod, _field, _indexers, [], _opts) do
    nil
  end

  def __extract_index_settings__(mod, field, indexers, entries, opts) when is_list(entries) do
    Enum.map(entries, &(FieldMacros.__extract_index_setting__(mod, field, indexers, &1, opts)))
    |> List.flatten()
    |> Enum.filter(&(&1))
  end

  def __extract_index_setting__(_mod, field, indexers, :field = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_uint = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_int = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_bigint = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_bool = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_multi = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_multi64 = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_timestamp = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, :attr_float = encoding, _opts), do: Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  def __extract_index_setting__(_mod, field, indexers, true, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true}}))
  end

  def __extract_index_setting__(_mod, field, indexers, false, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: false}}))
  end

  def __extract_index_setting__(mod, field, indexers, :inline, opts) do
    inline = Module.get_attribute(mod, :__nzdo__inline_index)
    FieldMacros.__extract_index_setting__(mod, field, indexers, inline, opts)
  end

  def __extract_index_setting__(mod, field, indexers, index, _opts) when is_atom(index) do
    cond do
      Enum.member?(indexers, index) -> {{field, index}, %{index: true}}
      :else -> raise "Index #{inspect index} not supported. You must include `@index #{index}` before declaring #{mod} if you wish to declare settings for this index."
    end
  end

  def __extract_index_setting__(mod, field, indexers, settings, opts) when is_list(settings) do
    Enum.map(settings, &(FieldMacros.__extract_index_setting__(mod, field, indexers, &1, opts)))
  end

  def __extract_index_setting__(_mod, field, indexers, {:bits, encoding}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, bits: encoding}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:encoding, encoding}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, encoding: encoding}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:as, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, as: setting}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:with, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, with: setting}}))
  end

  def __extract_index_setting__(_mod, field, indexers, {:user_defined, setting}, _opts) do
    Enum.map(indexers, &({{field, &1}, %{index: true, user_defined: setting}}))
  end

  def __extract_index_setting__(mod, field, indexers, {:inline, settings}, opts) do
    inline = Module.get_attribute(mod, :__nzdo__inline_index)
    FieldMacros.__extract_index_setting__(mod, field, indexers, {inline, settings}, opts)
  end

  def __extract_index_setting__(mod, field, indexers, {index, settings}, opts) when is_atom(index) do
    cond do
      Enum.member?(indexers, index) ->
        settings = is_list(settings) && settings || [settings]
        Enum.map(settings, &(FieldMacros.__extract_index_setting__(mod, field, index, indexers, &1, opts)))
      :else -> raise "Setting or Index #{inspect index} not supported. If this is an Index include `@index #{index}` before declaring #{mod}"
    end
  end

  def __extract_index_setting__(_mod, field, index, _indexers, true, _opts) do
    {{field, index}, %{index: true}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, false, _opts) do
    {{field, index}, %{index: false}}
  end


  def __extract_index_setting__(_mod, field, index, _indexers, {:bits, encoding}, _opts) do
    {{field, index}, %{index: true, bits: encoding}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:encoding, encoding}, _opts) do
    {{field, index}, %{index: true, encoding: encoding}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:as, setting}, _opts) do
    {{field, index}, %{index: true, as: setting}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:with, setting}, _opts) do
    {{field, index}, %{index: true, with: setting}}
  end

  def __extract_index_setting__(_mod, field, index, _indexers, {:user_defined, setting}, _opts) do
    {{field, index}, %{index: true, user_defined: setting}}
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_permission_settings__(mod, _field, _opts) do
    #entries = Module.get_attribute(mod, :permission)
    Module.delete_attribute(mod, :permission)
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_json_settings__(mod, field, opts) do
    config = Module.get_attribute(mod, :__nzdo__json_config)
    settings = Module.get_attribute(mod, :__nzdo__raw__json_format_settings, %{})
               |> FieldMacros.__extract_json_settings__(:json, mod, field, config, opts)
               |> FieldMacros.__extract_json_settings__(:json_embed, mod, field, config, opts)
               |> FieldMacros.__extract_json_settings__(:json_ignore, mod, field, config, opts)
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
    Enum.map(
      selectors,
      fn (selector) ->
        __expand_json_selector__(selector, config, opts)
      end
    )
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
    Enum.map(
      fields,
      fn (field) ->
        __expand_json_field__(field, config, opts)
      end
    )
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
    Enum.reduce(
      entries || [],
      acc,
      fn (entry, acc) ->
        {selectors, fields, settings} = __expand_json_entry__(entry, field, config, opts)
        Enum.reduce(
          settings,
          acc,
          fn (s, acc) ->
            case s do
              :expand -> __set_option__(acc, selectors, fields, {:expand, true})
              :sref -> __set_option__(acc, selectors, fields, {:sref, true})
              :ignore -> __set_option__(acc, selectors, fields, {:include, false})
              :include -> __set_option__(acc, selectors, fields, {:include, true})
              {:format, _} -> __set_option__(acc, selectors, fields, s)
              {:as, _} -> __set_option__(acc, selectors, fields, s)
              {:embed, embed} when is_atom(embed) ->
                embed = Map.new([{:embed, true}])
                __set_option__(acc, selectors, fields, {:embed, embed})
              {:embed, embed} when is_list(embed) ->
                embed = Enum.map(
                          embed,
                          fn (e) ->
                            case e do
                              e when is_atom(e) -> {e, true}
                              {e, f} -> {e, f}
                              _ -> nil
                            end
                          end
                        )
                        |> Enum.filter(&(&1))
                        |> Map.new()
                __set_option__(acc, selectors, fields, {:embed, embed})
              _ -> acc
            end
          end
        )
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_embed, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(
      entries,
      acc,
      fn (entry, acc) ->
        case entry do
          {selector, embed} when is_list(embed) ->
            selectors = __expand_json_selector__(selector, config, opts)
            embed = Enum.map(
                      embed,
                      fn (e) ->
                        case e do
                          e when is_atom(e) -> {e, true}
                          {e, f} -> {e, f}
                          _ -> nil
                        end
                      end
                    )
                    |> Enum.filter(&(&1))
                    |> Map.new()
            __set_option__(acc, selectors, [field], {:embed, embed})
          {selector, embed} when is_atom(embed) ->
            selectors = __expand_json_selector__(selector, config, opts)
            embed = Map.new([{:embed, true}])
            __set_option__(acc, selectors, [field], {:embed, embed})
          _ -> acc
        end
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __extract_json_settings__(acc, section = :json_ignore, mod, field, config, opts) do
    entries = Module.get_attribute(mod, section)
    Module.delete_attribute(mod, section)
    Enum.reduce(
      entries,
      acc,
      fn (entry, acc) ->
        case entry do
          {selector, fields} ->
            selectors = __expand_json_selector__(selector, config, opts)
            fields = __expand_json_field__(fields, config, opts)
            __set_option__(acc, selectors, fields, {:include, false})
          selector ->
            selectors = __expand_json_selector__(selector, config, opts)
            __set_option__(acc, selectors, [field], {:include, false})
        end
      end
    )
  end

  #---------------------------------
  #
  #---------------------------------
  def __set_option__(acc, formats, fields, {setting, setting_value}) do
    Enum.reduce(
      formats,
      acc,
      fn (format, acc) ->
        acc = update_in(acc, [format], &(&1 || %{}))
        Enum.reduce(
          fields,
          acc,
          fn (field, acc) ->
            acc = update_in(acc, [format, field], &(&1 || %{}))
            put_in(acc, [format, field, setting], setting_value)
          end
        )
      end
    )
  end



  defmacro __post_struct_definition_macro__(_) do
    quote do
      # Set Meta
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      Module.put_attribute(@__nzdo__base, :__nzdo__meta, (Module.has_attribute?(__MODULE__, :meta) && Module.get_attribute(__MODULE__, :meta) || []))

      #----------------------
      # fields meta data
      #----------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @__nzdo__field_types_map (
                                 (@__nzdo__field_types || [])
                                 |> Map.new())
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      @__nzdo__field_list (Enum.map(@__nzdo__fields, fn ({k, _}) -> k end) -- [:initial, :meta])

      #----------------------
      # Universals Fields (always include)
      #----------------------
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      #Module.put_attribute(__MODULE__, :__nzdo__fields, {:initial, nil})
      @inspect [ignore: true]
      FieldMacros.transient_field :initial

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      Module.put_attribute(__MODULE__, :__nzdo__fields, {:meta, %{}})

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      #Module.put_attribute(__MODULE__, :__nzdo__fields, {:__transient__, nil})
      @inspect [ignore: true]
      FieldMacros.transient_field :__transient__

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      Module.put_attribute(__MODULE__, :__nzdo__fields, {:vsn, @vsn})
      @file __ENV__.file
      :ok
    end
  end

  defmacro __register__field_attributes__macro__(_) do
    quote do
      Module.delete_attribute(__MODULE__, :index)
      Module.delete_attribute(__MODULE__, :meta)
      Module.delete_attribute(__MODULE__, :persistence_layer)
      Module.delete_attribute(__MODULE__, :json_white_list)
      Module.delete_attribute(__MODULE__, :json_format_group)
      Module.delete_attribute(__MODULE__, :json_field_group)

      # Pii Attribute
      Module.register_attribute(__MODULE__, :pii, accumulate: false)

      # Field Constraints
      Module.register_attribute(__MODULE__, :enum, accumulate: false)
      Module.register_attribute(__MODULE__, :required, accumulate: false)
      Module.register_attribute(__MODULE__, :ref, accumulate: true)
      Module.register_attribute(__MODULE__, :struct, accumulate: true)

      # Field Attributes
      Module.register_attribute(__MODULE__, :__nzdo__fields, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :__nzdo__field_types, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_attributes, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__identifier_type, accumulate: false)


      #Json Encoding Instructions
      Module.register_attribute(__MODULE__, :json, accumulate: true)
      Module.register_attribute(__MODULE__, :json_embed, accumulate: true)
      Module.register_attribute(__MODULE__, :json_ignore, accumulate: true)
      Module.register_attribute(__MODULE__, :json_restrict, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__raw__json_format_settings, accumulate: false)
      Module.put_attribute(__MODULE__, :__nzdo__raw__json_format_settings, %{})

      # Indexng
      Module.register_attribute(__MODULE__, :index, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_indexing, accumulate: true)

      # Permissions
      Module.register_attribute(__MODULE__, :permission, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__field_permissions, accumulate: true)
    end
  end


end
