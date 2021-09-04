#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.Index do
  @moduledoc """
  Indexing Functionality
  """

  defmodule Behaviour do
    alias Noizu.AdvancedScaffolding.Types
    @callback fields(any, any) :: any
    @callback build(any, any, any) :: any

    @callback update_index(any, any, any) :: any
    @callback delete_index(any, any, any) :: any

    @callback sql_escape_string(String.t) :: String.t

    @callback __extract_field__(any, any, any, any) :: any
    @callback __index_schema_fields__(any, any) :: any
    @callback __index_header__(any, any, any) :: any
    @callback __index_record__(any, any, any, any) ::any

    @callback __schema_open__() :: String.t
    @callback __schema_close__() :: String.t
    @callback __index_stem__() :: atom
    @callback __rt_index__() :: atom
    @callback __delta_index__() :: atom
    @callback __primary_index__() :: atom
    @callback __rt_source__() :: atom
    @callback __delta_source__() :: atom
    @callback __primary_source__() :: atom
    @callback __data_dir__() :: String.t

    @callback __noizu_info__() :: Keyword.t
    @callback __noizu_info__(Types.index_noizu_info_settings) :: any

    @callback __config__(any, any) :: any

    def __configure__(options) do
      options = Macro.expand(options, __ENV__)
      base = options[:stand_alone]
      index_stem = options[:index_stem]
      source_dir = options[:source_dir] || Application.get_env(:noizu_advanced_scaffolding, :sphinx_data_dir, "/sphinx/data")

      rt_index = options[:rt_index]
      delta_index = options[:delta_index]
      primary_index = options[:primary_index]

      rt_source = options[:rt_source]
      delta_source = options[:delta_source]
      primary_source = options[:primary_source]

      quote do
        #---------------------
        # Find Base
        #---------------------
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo__base  (unquote(base) && __MODULE__)|| (Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat())

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        @__nzdo__sref Module.get_attribute(@__nzdo__base, :__nzdo__sref) || Module.get_attribute(__MODULE__, :sref)

        @index_stem unquote(index_stem) || @__nzdo__sref
        @rt_index unquote(rt_index) || :"rt_index__#{@index_stem}"
        @delta_index unquote(delta_index) || :"delta_index__#{@index_stem}"
        @primary_index unquote(primary_index) || :"primary_index__#{@index_stem}"
        @rt_source unquote(rt_source) || :"rt_source__#{@index_stem}"
        @delta_source unquote(delta_source) || :"delta_source__#{@index_stem}"
        @primary_source unquote(primary_source) || :"primary_source__#{@index_stem}"
        @data_dir unquote(source_dir)

      end
    end

    def __implement__(options) do
      implementation = options[:index_implementation] || Noizu.AdvancedScaffolding.Internal.Index.Implementation.Default
      quote do
        @behaviour Noizu.AdvancedScaffolding.Internal.Index.Behaviour
        @__nzdo__index_implementation unquote(implementation)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def fields(context, options), do: @__nzdo__index_implementation.fields(__MODULE__, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def build(type, context, options), do: @__nzdo__index_implementation.build(__MODULE__, type, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def update_index(entity, context, options), do: @__nzdo__index_implementation.update_index(__MODULE__, entity, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def delete_index(entity, context, options), do: @__nzdo__index_implementation.delete_index(__MODULE__, entity, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def sql_escape_string(v), do: @__nzdo__index_implementation.sql_escape_string(v)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __schema_open__(), do: @__nzdo__index_implementation.__schema_open__()

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __schema_close__(), do: @__nzdo__index_implementation.__schema_close__()

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __extract_field__(field, entity, context, options), do: @__nzdo__index_implementation.__extract_field__(__MODULE__, field, entity, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __index_schema_fields__(context, options), do: @__nzdo__index_implementation.__index_schema_fields__(__MODULE__, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __index_header__(type, context, options), do: @__nzdo__index_implementation.__index_header__(__MODULE__, type, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __index_record__(type, entity, context, options), do: @__nzdo__index_implementation.__index_record__(__MODULE__, type, entity, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __index_stem__(), do: @index_stem
        def __rt_index__(), do: @rt_index
        def __delta_index__(), do: @delta_index
        def __primary_index__(), do: @primary_index
        def __rt_source__(), do: @rt_source
        def __delta_source__(), do: @delta_source
        def __primary_source__(), do: @primary_source
        def __data_dir__(), do: @data_dir

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def __config__(context, options), do: @__nzdo__index_implementation.__config__(__MODULE__, context, options)

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        defoverridable [
          fields: 2,
          build: 3,
          update_index: 3,
          delete_index: 3,
          sql_escape_string: 1,

          __schema_open__: 0,
          __schema_close__: 0,
          __extract_field__: 4,
          __index_schema_fields__: 2,
          __index_header__: 3,
          __index_record__: 4,

          __index_stem__: 0,
          __rt_index__: 0,
          __delta_index__: 0,
          __primary_index__: 0,
          __rt_source__: 0,
          __delta_source__: 0,
          __primary_source__: 0,
          __data_dir__: 0,

          __config__: 2,
        ]

      end
    end

    defmacro __before_compile__(_env) do
      quote do
        @settings [
          :type,
          :schema_open,
          :schema_close,
          :index_stem,
          :rt_index,
          :delta_index,
          :primay_index,
          :rt_source,
          :delta_source,
          :primary_source,
          :data_dir
        ]

        def __noizu_info__(), do: __noizu_info__(:all)
        def __noizu_info__(:all), do: Enum.map(@settings, &({&1, __noizu_info__(&1)}))
        def __noizu_info__(:type), do: :index
        def __noizu_info__(:schema_open), do: __schema_open__()
        def __noizu_info__(:schema_close), do: __schema_close__()
        def __noizu_info__(:index_stem), do: __index_stem__()
        def __noizu_info__(:rt_index), do: __rt_index__()
        def __noizu_info__(:delta_index), do: __delta_index__()
        def __noizu_info__(:primary_index), do: __primary_index__()
        def __noizu_info__(:rt_source), do: __rt_source__()
        def __noizu_info__(:delta_source), do: __delta_source__()
        def __noizu_info__(:primary_source), do: __primary_source__()
        def __noizu_info__(:data_dir), do: __data_dir__()

        defoverridable [
          __noizu_info__: 0,
          __noizu_info__: 1,
        ]
      end
    end

    def __after_compile__(_env, _bytecode) do
      # Validate Generated Object
      :ok
    end

  end
end
