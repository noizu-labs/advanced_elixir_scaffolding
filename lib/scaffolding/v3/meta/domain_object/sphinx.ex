defmodule Noizu.AdvancedScaffolding.Meta.DomainObject.Sphinx do

  def __noizu_sphinx__(_caller, _options, _block) do
    quote do
      import Noizu.ElixirCore.Guards

    end
  end

end
