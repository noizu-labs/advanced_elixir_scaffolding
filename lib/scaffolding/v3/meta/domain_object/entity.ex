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

end
