defmodule Noizu.AdvancedScaffolding.Meta.DomainObject.SphinxHandler do

  @type sphinx_encoding :: :field | :attr_uint | :attr_int | :attr_bigint | :attr_bool | :attr_multi | :attr_multi64 | :attr_timestamp | :attr_float | atom
  @callback __sphinx_field__() :: boolean
  @callback __sphinx_expand_field__(any, any, any) :: list
  @callback __sphinx_has_default__(any, any, any) :: boolean
  @callback __sphinx_default__(any, any, any) :: any
  @callback __sphinx_bits__(any, any, any) :: integer | :auto
  @callback __sphinx_encoding__(any, any, any) :: sphinx_encoding
  @callback __sphinx_encoded__(any, any, any, any) :: any

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_sphinx_handler__(_caller, options) do
    options = Macro.expand(options, __ENV__)
    quote do

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
      def __sphinx_field__(), do: true

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_expand_field__(field, indexing, _settings) do
        [
          {field, @handler, indexing}, #rather than __MODULE__ here we could use Sphinx providers like Sphinx.NullableInteger
        ]
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_has_default__(_field, _indexing, _settings), do: @has_default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_default__(_field, indexing, _settings), do: @default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_bits__(_field, _indexing, _settings), do: @sphinx_bits

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_encoding__(field, indexing, settings), do: @sphinx_encoding

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def __sphinx_encoded__(field, entity, _indexing, _settings) do
        get_in(entity, [Access.key(field)])
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
      ]
    end
  end

end
