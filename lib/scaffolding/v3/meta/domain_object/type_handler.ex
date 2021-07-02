defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.TypeHandler do
  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_type_handler__(_caller, _options) do
    quote do
      import Noizu.ElixirCore.Guards
      def pre_create_callback(_field, entity, _context, _options), do: entity
      def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)
      def pre_update_callback(_field, entity, _context, _options), do: entity
      def pre_update_callback!(field, entity, context, options), do: pre_update_callback(field, entity, context, options)
      def post_delete_callback(_field, entity, _context, _options), do: entity
      def post_delete_callback!(field, entity, context, options), do: post_delete_callback(field, entity, context, options)
      def cast(field, _segment, value, _type, _layer, _context, _options), do: {field, value}
      defoverridable [
        pre_create_callback: 4,
        pre_create_callback!: 4,
        pre_update_callback: 4,
        pre_update_callback!: 4,
        post_delete_callback: 4,
        post_delete_callback!: 4,
        cast: 7,
      ]
    end
  end

end
