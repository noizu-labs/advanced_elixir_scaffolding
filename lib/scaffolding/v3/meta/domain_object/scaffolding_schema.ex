defmodule Noizu.AdvancedScaffolding.Meta.DomainObject.ScaffoldingSchema do



  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_scaffolding_schema__(caller, options, block) do
    base_prefix = options[:base_prefix] || :auto
    database_prefix = options[:database_prefix] || :auto
    scaffolding_schema_provider = options[:scaffolding_schema_imp] || Noizu.AdvancedScaffolding.Implementation.DomainObject.Scaffolding.DefaultScaffoldingSchemaProvider
    app = options[:app] || throw "You must pass noizu_scaffolding_schema(app: :your_app)"
    s1 = quote do
           import Noizu.AdvancedScaffolding.DomainObject, only: [file_rel_dir: 1]
           require Noizu.AdvancedScaffolding.DomainObject
           require Noizu.AdvancedScaffolding.Meta.DomainObject.ScaffoldingSchema
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
                              |> Noizu.AdvancedScaffolding.Meta.Persistence.default_ecto_repo()
                              |> Module.split()
                              |> Enum.slice(0..-2)
                              |> Module.concat()
                            v -> v
                          end)

           #---------------------
           # Insure Single Call
           #---------------------
           @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
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
           @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
           try do
             # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
             import Noizu.AdvancedScaffolding.Meta.DomainObject.ScaffoldingSchema
             @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
             unquote(block)
           after
             :ok
           end

           :ok
         end


    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(s1)

      base_prefix = @base_prefix
      database_prefix = @database_prefix
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use unquote(scaffolding_schema_provider),
          base_prefix: base_prefix,
          database_prefix: database_prefix

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile unquote(scaffolding_schema_provider)
      @after_compile unquote(scaffolding_schema_provider)
      @file __ENV__.file
    end
  end




end
