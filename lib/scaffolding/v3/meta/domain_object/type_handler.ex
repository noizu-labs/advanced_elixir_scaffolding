defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.TypeHandler do

  @callback sync(any, any, any) :: any
  @callback sync(any, any, any, any) :: any
  @callback sync!(any, any, any) :: any
  @callback sync!(any, any, any, any) :: any

  @callback strip_inspect(any, any, any) :: any

  @callback pre_create_callback(any, any, any, any) :: any
  @callback pre_create_callback!(any, any, any, any) :: any

  @callback pre_update_callback(any, any, any, any) :: any
  @callback pre_update_callback!(any, any, any, any) :: any

  @callback post_delete_callback(any, any, any, any) :: any
  @callback post_delete_callback!(any, any, any, any) :: any

  @callback cast(any, any, any, any, any, any, any) :: any
  @callback dump(any, any, any, any, any, any) :: any

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_type_handler__(_caller, _options) do
    quote do
      import Noizu.ElixirCore.Guards


      def compare(nil, nil), do: :eq
      def compare(nil, _), do: :neq
      def compare(_, nil), do: :neq
      def compare(a, b), do: a ==b && :eq || :neq

      def sync(existing, update, context, options \\ nil)
      def sync(existing, nil, _context, _options), do: existing
      def sync(nil, update, _context, _options), do: update
      def sync(existing, _update, _context, _options), do: existing

      def sync!(existing, update, context, options \\ nil), do: sync(existing, update, context, options)

      def strip_inspect(field, value, _opts), do: {field, value}

      def post_get_callback(_field, entity, _context, _options), do: entity
      def post_get_callback!(field, entity, context, options), do: post_get_callback(field, entity, context, options)

      def pre_create_callback(_field, entity, _context, _options), do: entity
      def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)
      def post_create_callback(_field, entity, _context, _options), do: entity
      def post_create_callback!(field, entity, context, options), do: post_create_callback(field, entity, context, options)

      def pre_update_callback(_field, entity, _context, _options), do: entity
      def pre_update_callback!(field, entity, context, options), do: pre_update_callback(field, entity, context, options)
      def post_update_callback(_field, entity, _context, _options), do: entity
      def post_update_callback!(field, entity, context, options), do: post_update_callback(field, entity, context, options)

      def pre_delete_callback(_field, entity, _context, _options), do: entity
      def pre_delete_callback!(field, entity, context, options), do: pre_delete_callback(field, entity, context, options)
      def post_delete_callback(_field, entity, _context, _options), do: entity
      def post_delete_callback!(field, entity, context, options), do: post_delete_callback(field, entity, context, options)


      def cast(field, _segment, value, _type, _layer, _context, _options), do: {field, value}
      def dump(field, record, _type, _layer, _context, _options), do: [{field, record && get_in(record, [Access.key(:field)])}]

      def __sphinx_field__(), do: true
      def __sphinx_expand_field__(field, indexing, _settings) do
        indexing = update_in(indexing, [:from], &(&1 || field))
        {field, __MODULE__, indexing}
      end
      def __sphinx_has_default__(_field, _indexing, _settings), do: false
      def __sphinx_default__(_field, _indexing, _settings), do: nil
      def __sphinx_bits__(_field, _indexing, _settings), do: :auto
      def __sphinx_encoding__(_field, _indexing, _settings), do: :field
      def __sphinx_encoded__(_field, entity, indexing, _settings) do
        value = get_in(entity, [Access.key(indexing[:from])])
                |> Noizu.ERP.entity!()
        "EMBED: #{__MODULE__}"
      end


      defoverridable [
        compare: 2,
        sync: 3,
        sync: 4,
        sync!: 3,
        sync!: 4,
        strip_inspect: 3,
        post_get_callback: 4,
        post_get_callback!: 4,
        pre_create_callback: 4,
        pre_create_callback!: 4,
        post_create_callback: 4,
        post_create_callback!: 4,
        pre_update_callback: 4,
        pre_update_callback!: 4,
        post_update_callback: 4,
        post_update_callback!: 4,
        pre_delete_callback: 4,
        pre_delete_callback!: 4,
        post_delete_callback: 4,
        post_delete_callback!: 4,
        cast: 7,
        dump: 6,


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
