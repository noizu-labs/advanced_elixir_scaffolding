defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider do

  defmacro __before_compile__(_env) do
    quote do

    end
  end

  def __after_compile__(env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
