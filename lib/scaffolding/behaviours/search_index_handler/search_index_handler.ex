#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.SearchIndexHandler do
  @moduledoc """
  Behaviour for converting DomainObject.Entity fields to search engine format.
  This module provides a behaviour and implementation for handling search indexing on domain objects.
  It defines a set of callbacks for encoding and expanding fields, and handling permissions and search clauses.

  # Notes
  The `SearchIndexHandler` is responsible for handling search indexing on domain objects within the Noizu Elixir ecosystem. It is particularly useful when integrating a search engine like Sphinx to provide efficient and relevant search results for your application's data.

  Here's a breakdown of what the `SearchIndexHandler` does:

  1. **How it works**: It defines a behavior (`Noizu.DomainObject.SearchIndexHandler.Behaviour`) that requires implementing modules to provide specific callbacks. These callbacks are responsible for converting DomainObject.Entity fields to a format compatible with the search engine, handling permissions, and constructing search clauses.

  2. **What it does**: The `SearchIndexHandler` achieves the following functionalities:
   - Expands domain object entity fields to match the search engine's index fields.
   - Provides default values and field types for search engine compatibility.
   - Encodes fields to a format understood by the search engine.
   - Handles query permissions, determining if a specific field and filter combination is allowed for querying in a given context and options.
   - Constructs search clauses with permission filters applied.

  3. **Why it's useful**: By implementing the `SearchIndexHandler` behavior in your modules, you can efficiently convert your application's data (DomainObject.Entity fields) to a format that can be indexed and queried by a search engine like Sphinx. This enables you to provide relevant and accurate search results in your application, improving user experience and overall functionality.

  In summary, the `SearchIndexHandler` is a crucial component for integrating search functionality within an Elixir application. It handles the conversion of domain object data to a search engine-friendly format, manages query permissions, and constructs search clauses while adhering to the defined behavior.
  """

  defmodule Behaviour do
    @type sphinx_encoding :: :field | :attr_uint | :attr_int | :attr_bigint | :attr_bool | :attr_multi | :attr_multi_64 | :attr_timestamp | :attr_float | atom

    # ----- search construction
    alias Noizu.AdvancedScaffolding.Types, as: T
    @callback has_query_permission?(index :: any, field :: atom, filter :: atom | tuple, context :: Noizu.ElixirCore.CallingContext.t, options :: list | map()) :: true | false
    # search clauses with permision filters applied.
    @callback __search_clauses__(index :: any, settings :: tuple, conn :: any, params :: map(), context :: Noizu.ElixirCore.CallingContext.t, options :: list | map()) :: [T.query_clause] | {:error, any}
    # ----- search construction

    @callback __sphinx_field__() :: boolean
    @callback __sphinx_expand_field__(field :: atom, indexing :: map(), settings :: map()) :: any
    @callback __sphinx_has_default__(field :: atom, indexing :: map(), settings :: map()) :: boolean
    @callback __sphinx_default__(field :: atom, indexing :: map(), settings :: map()) :: any
    @callback __sphinx_bits__(field :: atom, indexing :: map(), settings :: map()) :: nil | integer | :auto
    @callback __sphinx_encoding__(field :: atom, indexing :: map(), settings :: map()) :: sphinx_encoding
    @callback __sphinx_encoded__(field :: atom, entity :: any, indexing :: map(), settings :: map()) :: any
  end

  #--------------------------------------------
  # __noizu_sphinx_handler__
  #--------------------------------------------
  @doc """
  Sphinx Handler Behavior
  """
  def __noizu_sphinx_handler__(_caller, options) do
    #options = Macro.expand(options, __ENV__)
    quote do
      @behaviour Noizu.DomainObject.SearchIndexHandler.Behaviour
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @handler (unquote(options[:handler]) || Module.get_attribute(__MODULE__, :sphinx_handler) || __MODULE__)
      @default unquote(options[:default])
      @default (@default != nil && @default || Module.get_attribute(__MODULE__, :sphinx_default))
      @has_default (cond do
                      @default != nil -> true
                      unquote(is_list(options) && Keyword.has_key?(options, :default)) -> true
                      unquote(is_map(options) && Map.has_key?(options, :default)) -> true
                      Module.has_attribute?(__MODULE__, :default) -> true
                      :else -> false
                    end)
      @sphinx_bits unquote(options[:bits]) || Module.get_attribute(__MODULE__, :sphinx_bits) || :auto
      @sphinx_encoding unquote(options[:encoding]) || Module.get_attribute(__MODULE__, :sphinx_encoding) || :attr_uint

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      is this module a sphinx_field handler?
      """
      def __sphinx_field__(), do: true

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Expand field from DomainObject.Entity into the list of index fields needed by sphinx.
      E.g. best_friend_name: %{first: f, last: l} could map to [best_friend_name_first, best_friend_name_last, best_friend_name_full]
      to allow searching our index for best friend by first name, last name or full name.
      """
      def __sphinx_expand_field__(field, indexing, _settings) do
        [
          {field, @handler, indexing}, #rather than __MODULE__ here we could use Sphinx providers like Sphinx.NullableInteger
        ]
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Does this (sub)field have a default value?.
      If we break a DomainObject.Entity field into multiple sub fields for sphinx we may inspect the per subfield `indexing` attribute here.
      For example if a field expands to subfields in our __sphinx_expand_field__ method we may inject a :sub attribute in that method specifying the name of each specific subfield.
      `[{:"\#{field}_my_sub_field", @handler, put_in(indexing, [:sub], :my_sub_field)}]`
      """
      def __sphinx_has_default__(_field, _indexing, _settings), do: @has_default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Default value for (Sub)field.
      If we break a DomainObject.Entity field into multiple sub fields for sphinx we may inspect the per subfield `indexing` attribute here.
      For example if a field expands to subfields in our __sphinx_expand_field__ method we may inject a :sub attribute in that method specifying the name of each specific subfield.
      `[{:"\#{field}_my_sub_field", @handler, put_in(indexing, [:sub], :my_sub_field)}]`
      """
      def __sphinx_default__(_field, indexing, _settings), do: @default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Integer bitwidth for (Sub)field.
      If we break a DomainObject.Entity field into multiple sub fields for sphinx we may inspect the per subfield `indexing` attribute here.
      For example if a field expands to subfields in our __sphinx_expand_field__ method we may inject a :sub attribute in that method specifying the name of each specific subfield.
      `[{:"\#{field}_my_sub_field", @handler, put_in(indexing, [:sub], :my_sub_field)}]`
      """
      def __sphinx_bits__(_field, _indexing, _settings), do: @sphinx_bits

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      (Sub)field sphinx field type: :attr_bigint, :attr_uint, :attr_multi_64, etc.
      If we break a DomainObject.Entity field into multiple sub fields for sphinx we may inspect the per subfield `indexing` attribute here.
      For example if a field expands to subfields in our __sphinx_expand_field__ method we may inject a :sub attribute in that method specifying the name of each specific subfield.
      `[{:"\#{field}_my_sub_field", @handler, put_in(indexing, [:sub], :my_sub_field)}]`
      """
      def __sphinx_encoding__(field, indexing, settings), do: @sphinx_encoding

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @doc """
      Cast (sub)field to format understood by sphinx. E.g. convert Enum atoms to their numeric value. Replace refs/entities with their universal numeric id
      If we break a DomainObject.Entity field into multiple sub fields for sphinx we may inspect the per subfield `indexing` attribute here.
      For example if a field expands to subfields in our __sphinx_expand_field__ method we may inject a :sub attribute in that method specifying the name of each specific subfield.
      `[{:"\#{field}_my_sub_field", @handler, put_in(indexing, [:sub], :my_sub_field)}]`
      """
      def __sphinx_encoded__(field, entity, _indexing, _settings) do
        get_in(entity, [Access.key(field)])
      end


      def has_query_permission?(index, field, filter, context, options) do
        case index.has_query_permission?(field, filter, context, options) do
          :inherit -> true
          v-> v
        end
      end

      def __search_clauses__(_index, _settings, _conn, _params, _context, _options) do
        nil
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        __sphinx_field__: 0,
        __sphinx_expand_field__: 3,
        __sphinx_has_default__: 3,
        __sphinx_default__: 3,
        __sphinx_bits__: 3,
        __sphinx_encoding__: 3,
        __sphinx_encoded__: 4,

        has_query_permission?: 5,
        __search_clauses__: 6,
      ]
    end
  end

end
