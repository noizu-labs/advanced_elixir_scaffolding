defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Struct.DefaultInternalProvider do

  defmacro __using__(_options \\ nil) do
    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      # We forward down tot he entity profider's implementations
      @__nzdo__internal_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider.Default

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def strip_pii(entity, level), do: @__nzdo__internal_imp.strip_pii(__MODULE__, entity, level)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def strip_inspect(entity, opts), do: @__nzdo__internal_imp.strip_inspect(__MODULE__, entity, opts)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def valid?(%__MODULE__{} = entity, context, options \\ nil), do: @__nzdo__internal_imp.valid?(__MODULE__, entity, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        strip_pii: 2,
        valid?: 2,
        valid?: 3,
      ]
    end
  end

  defmacro __before_compile__(_env) do
    quote do

    end
  end

  def __after_compile__(_env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
