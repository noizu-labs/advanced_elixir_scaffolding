defmodule Noizu.AdvancedScaffolding.Meta.Persistence do


  #--------------------------------------------
  #
  #--------------------------------------------
  def file_rel_dir(module_path) do
    offset = file_rel_dir(__ENV__.file, module_path, 0)
    String.slice(module_path, offset..- 1)
  end
  def file_rel_dir(<<m>> <> a, <<m>> <> b, acc) do
    file_rel_dir(a, b, 1 + acc)
  end
  def file_rel_dir(_a, _b, acc), do: acc

  #--------------------------------------------
  #
  #--------------------------------------------
  def module_rel(base, module_path) do
    [_ | a] = base
    [_ | b] = module_path
    offset = module_rel(a, b, 0)
    Enum.slice(module_path, (offset + 1)..- 1)
  end
  def module_rel([h | a], [h | b], acc) do
    module_rel(a, b, 1 + acc)
  end
  def module_rel(_a, _b, acc), do: acc



  def expand_persistence_layers(layers, module) when is_tuple(layers), do: expand_persistence_layers([layers], module)
  def expand_persistence_layers(nil, module), do: expand_persistence_layers([:mnesia], module)
  def expand_persistence_layers(layers, module) when is_atom(layers), do: expand_persistence_layers([layers], module)
  def expand_persistence_layers(layers, module) do
    layers = Enum.map(
      Enum.reverse(layers),
      fn (layer) ->
        case layer do
          v when is_atom(v) -> expand_layer(v, module, [])
          {v, t} when is_atom(t) -> expand_layer(v, t, module, [])
          {v, o} when is_list(o) -> expand_layer(v, module, o)
          {v, t, o} when is_atom(t) and is_list(o) -> expand_layer(v, t, module, o)
        end
      end
    )
    h = Module.get_attribute(module, :persistence)
    ecto_entity = cond do
                    is_list(h) && Keyword.has_key?(h, :ecto_entity) && h[:ecto_entity] != true -> h[:ecto_entity]
                    is_map(h) && Map.has_key?(h, :ecto_entity) && h[:ecto_entity] != true -> h[:ecto_entity]
                    :else ->
                      Enum.reduce_while(
                        layers,
                        nil,
                        fn (layer, acc) ->
                          cond do
                            layer.type == :ecto -> {:halt, layer.table}
                            :else -> {:cont, acc}
                          end
                        end
                      )
                  end

    layers = Enum.map(
      layers,
      fn (layer) ->
        {_, layer} = pop_in(layer, [Access.key(:options), :ref_module])
        {_, layer} = pop_in(layer, [Access.key(:options), :universal?])
        layer
      end
    )

    mnesia_backend = Enum.reduce(
      layers,
      nil,
      fn (layer, acc) ->
        cond do
          layer.type == :mnesia ->
            acc = update_in(
              acc || %{},
              [:dirty?],
              fn (p) ->
                cond do
                  p == false -> p
                  p == nil -> layer.dirty?
                  layer.dirty? == false -> false
                  :else -> p
                end
              end
            )

            acc = update_in(
              acc || %{},
              [:fragmented?],
              fn (p) ->
                cond do
                  p == true -> p
                  p == nil -> layer.fragmented?
                  layer.fragmented? == true -> true
                  :else -> p
                end
              end
            )

            acc = update_in(
              acc || %{},
              [:require_transaction?],
              fn (p) ->
                cond do
                  p == true -> p
                  p == nil -> layer.require_transaction?
                  layer.require_transaction? == true -> true
                  :else -> p
                end
              end
            )
            acc

          :else -> acc
        end
      end
    )

    enum_table = cond do
                   v = Module.get_attribute(module, :__nzdo__enum_list) -> v && true || false
                   :else -> false
                 end
    universal_identifier = cond do
                             Module.has_attribute?(module, :universal_identifier) -> Module.get_attribute(module, :universal_identifier, true)
                             enum_table -> false
                             :else -> Application.get_env(:noizu_advanced_scaffolding, :universal_identifier_default, true)
                           end
    universal_lookup = cond do
                         Module.has_attribute?(module, :universal_lookup) -> Module.get_attribute(module, :universal_lookup, true)
                         enum_table -> false
                         :else -> Application.get_env(:noizu_advanced_scaffolding, :universal_identifier_default, true)
                       end

    auto_generate = case Module.get_attribute(module, :__nzdo__auto_generate) do
                      true -> true
                      false -> false
                      _ -> !enum_table
                    end
    generate_reference_type_default = cond do
                                        enum_table -> false
                                        :else -> (universal_lookup || universal_identifier) && :universal_ref || false
                                      end
    generate_reference_type = cond do
                                Module.has_attribute?(module, :generate_reference_type) -> Module.get_attribute(module, :generate_reference_type)
                                :else -> generate_reference_type_default
                              end

    persistence_options = %{
      enum_table: enum_table,
      auto_generate: auto_generate,
      universal_identifier: universal_identifier,
      universal_lookup: universal_lookup,
      generate_reference_type: generate_reference_type,
    }

    schemas = Enum.map(layers || [], &({&1.schema, &1}))
              |> Map.new()
    tables = Enum.map(layers || [], &({&1.table, &1}))
             |> Map.new()

    %Noizu.AdvancedScaffolding.Schema.PersistenceSettings{
      layers: layers,
      schemas: schemas,
      tables: tables,
      mnesia_backend: mnesia_backend,
      ecto_entity: ecto_entity,
      options: persistence_options
    }
  end

  def expand_layer(provider, module, options) do
    provider = cond do
                 provider == :mnesia -> default_mnesia_database(module)
                 provider == :ecto -> default_ecto_repo(module)
                 provider == :redis -> default_redis_repo(module)
                 :else -> provider
               end

    case provider.metadata() do
      %Noizu.AdvancedScaffolding.Schema.RedisMetadata{} ->
        expand_layer(provider, {module, :redis}, module, options)
      metadata ->
        path = Module.split(module)
               |> Enum.slice(0..-2)
        root_table = Module.split(metadata.database)
        inner_path = module_rel(root_table, path)
        table = Module.concat(root_table ++ inner_path ++ ["Table"])
        expand_layer(provider, table, module, options)
    end

  end


  def expand_layer(provider, table, module, options) do
    provider = cond do
                 provider == :mnesia -> default_mnesia_database(module)
                 provider == :ecto -> default_ecto_repo(module)
                 provider == :redis -> default_redis_repo(module)
                 :else -> provider
               end

    metadata = provider.metadata()

    type = case metadata do
             %Noizu.AdvancedScaffolding.Schema.EctoMetadata{} -> :ecto
             %Noizu.AdvancedScaffolding.Schema.RedisMetadata{} -> :redis
             %Amnesia.Metadata{} -> :mnesia
             %Noizu.AdvancedScaffolding.Schema.Metadata{type: type} -> type
           end

    id_map = cond do
               options[:id_map] == nil -> :same
               options[:id_map] == false -> :unsupported
               :else -> options[:id_map]
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

    tx_block = cond do
                 type == :ecto ->
                   cond do
                     dirty? -> :none
                     :else -> :ecto_transaction
                   end
                 type == :mnesia ->
                   cond do
                     require_transaction? && fragmented? -> :fragment_tx
                     require_transaction? -> :tx
                     :else ->
                       case {dirty?, fragmented?} do
                         {:sync, true} -> :fragment_sync
                         {:sync, false} -> :sync
                         {:async, true} -> :fragment_async
                         {:async, false} -> :async
                         {true, true} -> :fragment_async
                         {true, false} -> :async
                         {false, true} -> :fragment_tx
                         {false, false} -> :tx
                         _ -> :none
                       end
                   end
                 :else -> :none
               end


    %Noizu.AdvancedScaffolding.Schema.PersistenceLayer{
      schema: provider,
      type: type,
      table: table,
      id_map: id_map,
      dirty?: dirty?,
      fragmented?: fragmented?,
      tx_block: tx_block,
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
    case Application.get_env(:noizu_advanced_scaffolding, :default_mnesia_database) do
      nil ->
        path = Module.split(module)
        Module.concat(["#{List.first(path)}" <> "Schema", "Database"])
      v -> v
    end
  end

  def default_ecto_repo(module) do
    case Application.get_env(:noizu_advanced_scaffolding, :default_ecto_database) do
      nil ->
        path = Module.split(module)
        Module.concat(["#{List.first(path)}" <> "Schema", "Repo"])
      v -> v
    end
  end

  def default_redis_repo(module) do
    case Application.get_env(:noizu_advanced_scaffolding, :default_redis_database) do
      nil ->
        path = Module.split(module)
        Module.concat(["#{List.first(path)}" <> "Schema", "Redis"])
      v -> v
    end
  end

end
