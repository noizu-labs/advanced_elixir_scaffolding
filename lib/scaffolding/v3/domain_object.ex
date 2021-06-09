defmodule Noizu.DomainObject do


  defmacro __using__(options \\ nil) do
    nmid_generator = options[:nmid_generator] || Noizu.Scaffolding.V3.NmidGenerator
    nmid_sequencer = options[:nmid_sequencer]
    nmid_index = options[:nmid_index] || 1
    caller = __CALLER__
    quote do
      import Noizu.DomainObject, only: [file_rel_dir: 1]
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: true)

      # Insure only referenced once.
      if line = Module.get_attribute(__MODULE__, :__nzdo__base_definied) do
        raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} duplicate use Noizu.DomainObject reference. First defined on #{elem(line,0)}:#{elem(line,1)}"
      end
      @__nzdo__base_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

      @__nzdo_nmid_generatoer unquote(nmid_generator)
      @__nzdo_nmid_index unquote(nmid_index)
      @__nzdo_nmid_sequencer (unquote(nmid_sequencer) || __MODULE__)

      @before_compile {Noizu.DomainObject, :before_compile_domain_object__base}
    end
  end

  defmacro before_compile_domain_object__base(_) do
    quote do

      defdelegate id(ref), to: @__nzdo__entity
      defdelegate ref(ref), to: @__nzdo__entity
      defdelegate sref(ref), to: @__nzdo__entity
      defdelegate entity(ref, options \\ nil), to: @__nzdo__entity
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record!(ref, options \\ nil), to: @__nzdo__entity
      defdelegate __noizu_record__(type, ref, options \\ nil), to: @__nzdo__entity

      def __noizu_info__(:type), do: :base
      def __noizu_info__(:base), do: __MODULE__
      def __noizu_info__(:entity), do: @__nzdo__entity
      def __noizu_info__(:repo), do: @__nzdo__repo
      def __noizu_info__(:sref), do: @__nzdo__sref
      def __noizu_info__(:nmid_generator), do: @__nzdo_nmid_generatoer
      def __noizu_info__(:nmid_index), do: @__nzdo_nmid_index
      def __noizu_info__(:nmid_sequencer), do: @__nzdo_nmid_sequencer
      def __noizu_info__(:fields), do: @__nzdo__entity.__noizu_info__(:fields)
      def __noizu_info__(:field_types), do: @__nzdo__entity.__noizu_info__(:field_types)
      def __noizu_info__(:persistence), do: @__nzdo__entity.__noizu_info__(:persistence)
      @__nzdo__meta__map Map.new(@__nzdo__meta)
      def __noizu_info__(:meta), do: @__nzdo__meta__map
    end
  end

  defmacro before_compile_domain_object__entity(_) do
    quote do
      def __noizu_info__(:fields), do: @__nzdo__field_list
      def __noizu_info__(:field_types), do: @__nzdo__field_types_map
      def __noizu_info__(:persistence), do: @__nzdo_persistence
      defdelegate __noizu_info__(report), to: @__nzdo__base
    end
  end
  defmacro before_compile_domain_object__repo(_) do
    quote do
      defdelegate id(ref), to: @__nzdo__base
      defdelegate ref(ref), to: @__nzdo__base
      defdelegate sref(ref), to: @__nzdo__base
      defdelegate entity(ref, options \\ nil), to: @__nzdo__base
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__base
      defdelegate record(ref, options \\ nil), to: @__nzdo__base
      defdelegate record!(ref, options \\ nil), to: @__nzdo__base
      defdelegate __noizu_record__(type, ref, options \\ nil), to: @__nzdo__base
      defdelegate __noizu_info__(report), to: @__nzdo__base
    end
  end


  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_entity(options \\ [], [do: block]) do
    __noizu_entity(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defp __noizu_entity(caller, options, block) do
    erp_provider = options[:erp_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider
    ecto_provider = options[:ecto_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultInternalProvider
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__entity_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_entity first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end
                       @__nzdo__entity_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @__nzdo__base Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
                       if !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

                       #---------------------
                       # Insure sref set
                       #---------------------
                       if !Module.get_attribute(@__nzdo__base, :sref) do
                         raise "@sref must be defined in base module #{@__ndzo__base} before calling defentity in submodule #{__MODULE__}"
                       end

                       #---------------------
                       # Push details to Base, and read in required settings.
                       #---------------------
                       @__nzdo__repo Module.concat(@__nzdo__base, "Repo")
                       @__nzdo__sref Module.get_attribute(@__nzdo__base, :sref)
                       Module.put_attribute(@__nzdo__base, :__nzdo__entity, __MODULE__)
                       Module.put_attribute(@__nzdo__base, :__nzdo__sref, @__nzdo__sref)

                       @vsn (Module.get_attribute(@__nzdo__base, :vsn) || 1.0)

                       Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__fields, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_permissions, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_types, accumulate: true)

                       #----------------------
                       # Always hook into Noizu.ERP
                       #----------------------
                       @__nzdo__derive Noizu.ERP

                       #----------------------
                       # Load Persistence Settings from base, we need them to control some submodules.
                       #----------------------
                       @__nzdo_persistence Noizu.DomainObject.expand_persistence_layers(Module.get_attribute(@__nzdo__base, :persistence_layer), __MODULE__)
                       @__nzdo__field_types_map ((@__nzdo__field_types || []) |> Map.new())
                       @__nzdo__field_list (Enum.map(@__nzdo__fields, fn({k,_}) -> k end) -- [:initial, :meta])
                       @__nzdo_persistence__layers Enum.map(@__nzdo_persistence.layers, fn(layer) -> {layer.layer, layer} end) |> Map.new()
                       @__nzdo_ecto_entity (@__nzdo_persistence.ecto_entity && true || false)
                       if @__nzdo_ecto_entity do
                         @derive_list Noizu.Ecto.Entity
                       end

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity
                         unquote(block)
                       after
                         :ok
                       end

                       #----------------------
                       # Universals Fields (always include)
                       #----------------------
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:initial, nil})
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:meta, %{}})
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:vsn, @vsn})
                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields




                 #-----------------------------------
                 #
                 #-----------------------------------
                 def vsn(), do: @vsn
                 def __repo__(), do: @__nzdo__repo
                 def __sref__(), do: @__nzdo__sref
                 def __erp__(), do: __MODULE__

                 defoverridable [
                   vsn: 0,
                   __repo__: 0
                 ]
               end

    quote do
      unquote(process_config)
      unquote(generate)
      use unquote(erp_provider)
      use unquote(ecto_provider)

      # Post User Logic Hook and checks.
      @before_compile unquote(internal_provider)
      @before_compile {Noizu.DomainObject, :before_compile_domain_object__entity}
      @after_compile unquote(internal_provider)
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_repo(options \\ [], [do: block]) do
    __noizu_repo(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defp __noizu_repo(caller, options, block) do
    crud_provider = options[:erp_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultCrudProvider
    internal_provider = options[:internal_imp] || Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Repo.DefaultInternalProvider
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__repo_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_repo first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end
                       @__nzdo__repo_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @__nzdo__base Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
                       if !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

                       #---------------------
                       # Insure sref set
                       #---------------------
                       if !Module.get_attribute(@__nzdo__base, :sref) do
                         raise "@sref must be defined in base module #{@__ndzo__base} before calling defentity in submodule #{__MODULE__}"
                       end

                       #---------------------
                       # Push details to Base, and read in required settings.
                       #---------------------
                       Module.put_attribute(@__nzdo__base, :__nzdo__repo, __MODULE__)
                       @__nzdo__entity Module.concat(@__nzdo__base, "Entity")
                       @__nzdo__sref Module.get_attribute(@__nzdo__base, :sref)
                       @vsn (Module.get_attribute(@__nzdo__base, :vsn) || 1.0)

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo
                         unquote(block)
                       after
                         :ok
                       end
                     end

    quote do
      unquote(process_config)
      use unquote(crud_provider)

      # Post User Logic Hook and checks.
      @before_compile unquote(internal_provider)
      @before_compile {Noizu.DomainObject, :before_compile_domain_object__repo}
      @after_compile unquote(internal_provider)
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
