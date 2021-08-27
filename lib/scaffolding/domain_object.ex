defmodule Noizu.DomainObject do

  @doc """
  Setup Base Domain Object, this struct will in turn hold Entity, Repo, Index, etc.
  @example ```
  defmodule User do
    use Noizu.DomainObject
    Noizu.DomainObject.noizu_entity() do
      public_field :name
    end
  end
  ```
  """
  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    quote do
      use Noizu.AdvancedScaffolding.Internal.DomainObject.Base, unquote(options)
    end
  end

  #--------------------------------------------
  # noizu_entity
  #--------------------------------------------
  @doc """
  Initialize a DomainObject.Entity. Caller passes in identifier and field definitions which are in turn used to generate the domain object entity's configuration options and defstruct statement.
  @example ```
  defmodule User do
    use Noizu.DomainObject
    Noizu.DomainObject.noizu_entity() do
      public_field :name
    end
  end
  ```
  """
  defmacro noizu_entity(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_table
  #--------------------------------------------
  defmacro noizu_table(options \\ []) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Table.__noizu_table__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_scaffolding_schema
  #--------------------------------------------
  defmacro noizu_scaffolding_schema(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.DomainObject.SchemaInfo.__noizu_scaffolding_schema__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_type_handler
  #--------------------------------------------
  defmacro noizu_type_handler(options \\ []) do
    options = Macro.expand(options, __ENV__)
    Noizu.DomainObject.TypeHandler.__noizu_type_handler__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_sphinx_handler
  #--------------------------------------------
  defmacro noizu_sphinx_handler(options \\ []) do
    options = Macro.expand(options, __ENV__)
    Noizu.DomainObject.SearchIndexHandler.__noizu_sphinx_handler__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_index
  #--------------------------------------------
  defmacro noizu_index(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Index.__noizu_index__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_repo
  #--------------------------------------------
  defmacro noizu_repo(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
  end


end
