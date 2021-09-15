#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject do

  @doc """
  Setup Base Domain Object, this struct will in turn hold Entity, Repo, Index, etc.

  ## See
  - `Noizu.AdvancedScaffolding.Internal.Core.Base.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.Persistence.Base.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.EntityIndex.Base.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.Json.Base.Behaviour`

  ## Example
  ```elixir
  defmodule User do
    use Noizu.DomainObject
    Noizu.DomainObject.noizu_entity() do
      public_field :name
    end
  end
  ```
  """
  defmacro __using__(options \\ nil) do
    #options = Macro.expand(options, __ENV__)
    quote do
      use Noizu.AdvancedScaffolding.Internal.DomainObject.Base, unquote(options)
    end
  end

  #--------------------------------------------
  # noizu_entity
  #--------------------------------------------
  @doc """
  Initialize a DomainObject.Entity. Caller passes in identifier and field definitions which are in turn used to generate the domain object entity's configuration options and defstruct statement.

  ## See
  - `Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.Index.Behaviour`
  - `Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour`

  ## Example
  ```elixir
  defmodule User do
    use Noizu.DomainObject
    Noizu.DomainObject.noizu_entity() do
      public_field :name
    end
  end
  ```
  """
  defmacro noizu_entity(options \\ [], [do: block]) do
    #options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_table
  #--------------------------------------------
  @doc """
    Inject Scaffolding fields into a Ecto.Table entity.
  """
  defmacro noizu_table(options \\ []) do
    #options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Table.__noizu_table__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_schema_info
  #--------------------------------------------
  @doc """
    Configure your DomainObject Schema module. Provides runtime compiled list of modules, sref mapping/Noizu.ERP String.t support, etc.
  """
  defmacro noizu_schema_info(options \\ [], [do: block]) do
    #options = Macro.expand(options, __ENV__)
    Noizu.DomainObject.SchemaInfo.__noizu_schema_info__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_type_handler
  #--------------------------------------------
  @doc """
    Type Handler Behavior. Used for casting/loading embedded fields into their persistence layer format.
    For example domain objects may include a TimeStamp field.


    ```elixir
    defmodule Entity do
      @universal_identifier true
      Noizu.DomainObject.noizu_entity do
        @index true
        public_field :my_image_update, nil, Noizu.Scaffolding.V3.TimeStamp.TypeHandler
      end
    end
    ```

    Where the time stamp field contains a created_on, modified_on, deleted_on field. When  casting to  an Ecto database the nested structure can be replaced
    with `my_image_update_created_on` ,`my_image_update_modified_on` ,and `my_image_update_deleted_on` which would match DateTime fields in our Ecto  Table schema.


   ```elixir
    defmodule Noizu.DomainObject.TimeStamp.Second do
      use Noizu.SimpleObject
      @vsn 1.0
      Noizu.SimpleObject.noizu_struct() do
        date_time_handler = Application.get_env(:noizu_advanced_scaffolding, :data_time_handler, Noizu.DomainObject.DateTime.Second.TypeHandler)
        public_field :created_on, nil, date_time_handler
        public_field :modified_on, nil, date_time_handler
        public_field :deleted_on, nil, date_time_handler
      end
     #...
    ```
  """
  defmacro noizu_type_handler(options \\ []) do
    #options = Macro.expand(options, __ENV__)
    Noizu.DomainObject.TypeHandler.__noizu_type_handler__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_sphinx_handler
  #--------------------------------------------
  @doc """
  Similar to type handler, but responsible for casting fields to a sphinx index record.
  In addition the field expansion support like in our type handler behaviour it also provides default values, field type (:attr_unit, :attr_multi64, :field), and bit width (for int fields).
  """
  defmacro noizu_sphinx_handler(options \\ []) do
    #options = case options do
    #            [] -> []
    #            _ -> Macro.expand(options, __ENV__)
    #          end
    Noizu.DomainObject.SearchIndexHandler.__noizu_sphinx_handler__(__CALLER__, options)
  end

  #--------------------------------------------
  # noizu_index
  #--------------------------------------------
  @doc """
  Module for handling saving to/ updating/tracking and creating Sphinx record types.
  Provides methods for creating xml schema definitions, real time definitions, config snippets,
  internal book keeping (for tracking if a record is realtime, delta, primary index), etc.
  """
  defmacro noizu_index(options \\ [], [do: block]) do
    #options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Index.__noizu_index__(__CALLER__, options, block)
  end

  #--------------------------------------------
  # noizu_repo
  #--------------------------------------------
  @doc """
  Provides scaffolding for a DomainObject.Repo module. If used with no options this behavior wll provide everything needed for basic crud. get/cache/update/delete  as well as
  providing by default a simple repo structure  %Repo{ entities: [], length: 0} which may be used to pass round specific sets of records or as an embed option for domain objects
  provided ta TypeHandler and optional SphinxHandler is provided.

  ## Example
  ```elixir
  defmodule MyApp.MyDomainObject do
    ...
    defmodule Repo do
       Noizu.DomainObject.noizu_repo do
       end
    end

    defmodule Repo.TypeHandler do
      require  Noizu.DomainObject
      Noizu.DomainObject.noizu_type_handler()
    end

    def pre_create_callback(field, entity, context, options) do
        # a domain object included a Repo set of entities of type MyApp.DomainObject.Entity. From this callback we may write each of these to a 12m table  for our entity.
        super(field, entity, context, options)
    end
  end
  ```
  """
  defmacro noizu_repo(options \\ [], [do: block]) do
    #options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
  end


end
