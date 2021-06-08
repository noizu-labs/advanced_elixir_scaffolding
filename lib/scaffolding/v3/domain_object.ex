defmodule Noizu.DomainObject do
  @doc false
  defmacro __using__(_ \\ nil) do
    quote do
      import Noizu.DomainObject, only: [defentity: 1, defentity: 2, defrepo: 2, defrepo: 1, file_rel_dir: 1]
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro defentity(options \\ [], [do: block]) do
    __defentity(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defp __defentity(caller, options, block) do
    provider = options[:provider] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.Default
    process_config = quote do
                       @domain_object Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
                       @repo Module.concat(@domain_object, "Repo")

                       if line = Module.get_attribute(__MODULE__, :noizu_entity_defined) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.defentity first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end

                       if !Module.get_attribute(@domain_object, :sref_module) do
                         raise "@sref_module must be defined before calling defentity"
                       end

                       @sref_module Module.get_attribute(@domain_object, :sref_module)
                       @provider unquote(provider)
                       @noizu_entity_defined { file_rel_dir(unquote(caller.file)), unquote(caller.line)}
                       Module.register_attribute(__MODULE__, :entity_fields, accumulate: true)
                       Module.register_attribute(__MODULE__, :entity_fields_access_level, accumulate: true)
                       Module.register_attribute(__MODULE__, :derive_list, accumulate: true)
                       Module.register_attribute(__MODULE__, :entity_field_types, accumulate: true)

                       #----------------------
                       #
                       #----------------------
                       @derive_list Noizu.ERP

                       #----------------------
                       #
                       #----------------------
                       @vsn (Module.get_attribute(@domain_object, :vsn) || 1.0)


                       #----------------------
                       #
                       #----------------------
                       @persistence_layer_settings Noizu.DomainObject.expand_persistence_layers(Module.get_attribute(@domain_object, :persistence_layer), __MODULE__)
                       @is_noizu_mysql_entity @persistence_layer_settings.ecto_entity && true || false
                       if @is_noizu_mysql_entity do
                         @derive_list Noizu.MySQL.Entity
                       end

                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         unquote(block)
                       after
                         :ok
                       end

                       # Universals
                       Module.put_attribute(__MODULE__, :entity_fields, {:initial, nil})
                       Module.put_attribute(__MODULE__, :entity_fields, {:meta, %{}})
                       Module.put_attribute(__MODULE__, :entity_fields, {:vsn, @vsn})
                     end

    generate = quote unquote: false do

               end

    prepare_struct = quote do
                       @derive @derive_list
                       defstruct Enum.reverse(@entity_fields)
                     end

    quote do
      unquote(process_config)
      unquote(generate)
      unquote(prepare_struct)

      @before_compile unquote(provider)
      @after_compile unquote(provider)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro defrepo(options \\ [], [do: block]) do
    __defrepo(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defp __defrepo(caller, options, block) do
    provider = options[:provider] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.Default
    process_config = quote do
                       use Amnesia
                       require Amnesia.Fragment
                       @domain_object Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
                       @entity Module.concat(@domain_object, "Entity")

                       if line = Module.get_attribute(__MODULE__, :noizu_repo_defined) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.defrepo first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end

                       @provider unquote(provider)
                       @noizu_repo_defined {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         unquote(block)
                       after
                         :ok
                       end
                     end

    generate = quote unquote: false do

               end

    quote do
      unquote(process_config)
      unquote(generate)
      @before_compile unquote(provider)
      @after_compile unquote(provider)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def file_rel_dir(module_path) do
    offset = file_rel_dir(__ENV__.file, module_path, 0)
    String.slice(module_path, offset .. - 1)
  end
  def file_rel_dir(<<m>> <> a, <<m>> <> b, acc) do
    file_rel_dir(a, b, 1 + acc)
  end
  def file_rel_dir(_a, _b, acc), do: acc

  #--------------------------------------------
  #
  #--------------------------------------------
  def module_rel(base, module_path) do
    [_|a] = base
    [_|b] = module_path
    offset = module_rel(a, b, 0)
    Enum.slice(module_path, (offset + 1).. - 1)
  end
  def module_rel([h|a], [h|b], acc) do
    module_rel(a, b, 1 + acc)
  end
  def module_rel(_a, _b, acc), do: acc



  def expand_persistence_layers(layers, module) when is_tuple(layers), do: expand_persistence_layers([layers], module)
  def expand_persistence_layers(nil, module), do: expand_persistence_layers([:mnesia], module)
  def expand_persistence_layers(layers, module) when is_atom(layers), do: expand_persistence_layers([layers], module)
  def expand_persistence_layers(layers, module) do

    layers = Enum.map(Enum.reverse(layers), fn(layer) ->
      case layer do
        v when is_atom(v) -> expand_layer(v, module, [])
        {v, t} when is_atom(t) -> expand_layer(v, t, module, [])
        {v, o} when is_list(o) -> expand_layer(v, module, o)
        {v, t, o} when is_atom(t) and is_list(o) -> expand_layer(v,t,module,o)
      end
    end)
    h = layers && List.first(layers)
    ecto_entity = cond do
                    h == nil -> false
                    h.options[:ecto_entity] == false -> false
                    h.options[:ecto_entity] && h.options[:ecto_entity] != true && is_atom(h.options[:ecto_entity]) -> h.options[:ecto_entity]
                    :else ->
                      Enum.reduce_while(layers, nil, fn(layer, acc) ->
                        cond do
                          layer.type == :ecto -> {:halt, layer.table}
                          :else -> {:cont, acc}
                        end
                      end)
                  end
    urm = cond do
            h == nil -> false
            h.options[:ref_module] == false -> false
            :else -> true
          end
    uid = cond do
            h == nil -> false
            h.options[:universal?] == false -> false
            :else -> true
          end
    layers = Enum.map(layers, fn(layer) ->
      {_, layer} = pop_in(layer, [Access.key(:options), :ref_module])
      {_, layer} = pop_in(layer, [Access.key(:options), :universal?])
      layer
    end)

    mnesia_backend = Enum.reduce(layers, nil, fn(layer, acc) ->
        cond do
          layer.type == :mnesia ->
            acc = update_in(acc || %{}, [:dirty?], fn(p) ->
              cond do
                p == false -> p
                p == nil -> layer.dirty?
                layer.dirty? == false -> false
                :else -> p
              end
            end)

            acc = update_in(acc || %{}, [:fragmented?], fn(p) ->
              cond do
                p == true -> p
                p == nil -> layer.fragmented?
                layer.fragmented? == true -> true
                :else -> p
              end
            end)

            acc = update_in(acc || %{}, [:require_transaction?], fn(p) ->
              cond do
                p == true -> p
                p == nil -> layer.require_transaction?
                layer.require_transaction? == true -> true
                :else -> p
              end
            end)
            acc

          :else -> acc
        end
    end)

    %Noizu.Scaffolding.V3.Schema.PersistenceSettings{
      layers: layers,
      mnesia_backend: mnesia_backend,
      ecto_entity: ecto_entity,
      ref_module: urm,
      universal?: uid,
    }
  end



  def expand_layer(provider, module, options) do
    provider = cond do
                 provider == :mnesia -> default_mnesia_database(module)
                 provider == :ecto -> default_ecto_repo(module)
                 :else -> provider
               end

    metadata = provider.metadata()
    path = Module.split(module) |> Enum.slice(0 .. -2)
    root_table = Module.split(metadata.database)
    inner_path = module_rel(root_table, path)
    table = Module.concat(root_table ++ inner_path ++ ["Table"])
    expand_layer(provider, table, module, options)
  end


  def expand_layer(provider, table, module, options) do
    provider = cond do
                 provider == :mnesia -> default_mnesia_database(module)
                 provider == :ecto -> default_ecto_repo(module)
                 :else -> provider
               end

    metadata = provider.metadata()

    type = case metadata do
             %Noizu.Scaffolding.V3.Schema.EctoMetadata{} -> :ecto
             %Amnesia.Metadata{} -> :mnesia
           end
    type = case metadata do
             %Noizu.Scaffolding.V3.Schema.EctoMetadata{} -> :ecto
             %Amnesia.Metadata{} -> :mnesia
           end

    dirty? = cond do
               options[:dirty?] == false -> false
               :else -> true
             end
    fragmented? = cond do
                    options[:fragmented?] == true -> true
                    :else -> false
                  end
    require_transaction? = cond do
                             options[:require_transaction?] == true -> true
                             :else -> false
                           end

    load_fallback? = cond do
                       options[:load_fallback?] == true -> true
                       type == :mnesia -> true
                       type == :ecto -> true
                       :else -> false
                     end

    cascade? = cond do
                 options[:cascade?] == true -> true
                 options[:cascade?] == false -> false
                 type == :mnesia -> true
                 :else -> false
               end

    cascade_create? = cond do
                        options[:cascade_create?] == true -> true
                        :else -> cascade?
                      end
    cascade_update? = cond do
                        options[:cascade_update?] == true -> true
                        :else -> cascade?
                      end
    cascade_delete? = cond do
                        options[:cascade_delete?] == true -> true
                        :else -> cascade?
                      end
    cascade_block? = cond do
                       options[:cascade_block?] == true -> true
                       :else -> false
                     end

    %Noizu.Scaffolding.V3.Schema.PersistenceLayer{
      layer: provider,
      type: type,
      table: table,

      dirty?: dirty?,
      fragmented?: fragmented?,
      require_transaction?: require_transaction?,

      load_fallback?: load_fallback?,

      cascade_create?: cascade_create?,
      cascade_delete?: cascade_delete?,
      cascade_update?: cascade_update?,
      cascade_block?: cascade_block?,

      options: options || [],
    }
  end

  def default_mnesia_database(module) do
    path = Module.split(module)
    Module.concat(["#{List.first(path)}" <> "Schema", "Database"])
  end

  def default_ecto_repo(module) do
    path = Module.split(module)
    Module.concat(["#{List.first(path)}" <> "Schema", "Repo"])
  end

end
