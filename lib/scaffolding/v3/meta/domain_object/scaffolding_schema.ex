defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.ScaffoldingSchema do



  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_scaffolding_schema__(caller, options, block) do
    base_prefix = options[:base_prefix] || :auto
    database_prefix = options[:database_prefix] || :auto
    scaffolding_schema_provider = options[:scaffolding_schema_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider
    macro_file = __ENV__.file
    app = options[:app] || throw "You must pass noizu_scaffolding_schema(app: :your_app)"
    s1 = quote do
           import Noizu.DomainObject, only: [file_rel_dir: 1]
           require Noizu.DomainObject
           require Noizu.ElixirScaffolding.V3.Meta.DomainObject.ScaffoldingSchema
           import Noizu.ElixirCore.Guards
           @options unquote(options)
           @app unquote(app)
           @base_prefix (case unquote(base_prefix) do
                    :auto -> Module.concat([List.first(Module.split(__MODULE__))])
                    v -> v
                  end)
           @database_prefix (case unquote(database_prefix) do
                            :auto ->
                              __MODULE__
                              |> Noizu.ElixirScaffolding.V3.Meta.Persistence.default_ecto_repo()
                              |> Module.split()
                              |> Enum.slice(0..-2)
                              |> Module.concat()
                            v -> v
                          end)

           #---------------------
           # Insure Single Call
           #---------------------
           @file unquote(macro_file) <> "<single_call>"
           if line = Module.get_attribute(__MODULE__, :__nzdo__scaffolding_definied) do
             raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_scaffolding_schema first defined on #{elem(line, 0)}:#{
               elem(line, 1)
             }"
           end
           @__nzdo__scaffolding_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

           Module.register_attribute(__MODULE__, :cache_keys, accumulate: false)

           #----------------------
           # User block section (define, fields, constraints, json_mapping rules, etc.)
           #----------------------
           try do
             # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
             import Noizu.ElixirScaffolding.V3.Meta.DomainObject.ScaffoldingSchema
             @file unquote(macro_file) <> "<block>"
             unquote(block)
           after
             :ok
           end

           :ok
         end


    quote do
      @file unquote(macro_file) <> "<segment_one>"
      unquote(s1)

      base_prefix = @base_prefix
      database_prefix = @database_prefix
      @file unquote(macro_file) <> "<scaffolding_schema_provider>"
      use unquote(scaffolding_schema_provider),
          base_prefix: base_prefix,
          database_prefix: database_prefix

      @before_compile unquote(scaffolding_schema_provider)
      @after_compile unquote(scaffolding_schema_provider)
    end
  end




end
