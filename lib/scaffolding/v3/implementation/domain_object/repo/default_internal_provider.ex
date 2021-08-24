defmodule Noizu.AdvancedScaffolding.Implementation.DomainObject.Repo.DefaultInternalProvider do

  defmacro __before_compile__(_env) do
    quote do
      # Catch alls to allow one off overrides.
    end
  end

  def __after_compile__(_env, _bytecode) do

  end

end
