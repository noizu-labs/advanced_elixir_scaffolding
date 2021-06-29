defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index do


  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_index__(caller, options, block) do
    indexer = case options[:engine] do
                nil -> Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Index.DefaultSphinxProvider
                :sphinx -> Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Index.DefaultSphinxProvider
                v when is_atom(v) -> v
              end

    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__index_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_index first defined on #{elem(line, 0)}:#{
                           elem(line, 1)
                         }"
                       end
                       @__nzdo__index_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @__nzdo__base Module.split(__MODULE__)
                                     |> Enum.slice(0..-2)
                                     |> Module.concat()
                       if !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index
                         unquote(block)
                       after
                         :ok
                       end
                     end

    quote do
      unquote(process_config)
      use unquote(indexer)

      # Post User Logic Hook and checks.
      #@before_compile unquote(internal_provider)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index
      #@after_compile unquote(internal_provider)
    end
  end



  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    quote do

      defdelegate vsn(), to: @__nzdo__base
      def __base__(), do: @__nzdo__base
      defdelegate __entity__(), to: @__nzdo__base
      defdelegate __repo__(), to: @__nzdo__base
      defdelegate __sref__(), to: @__nzdo__base
      defdelegate __erp__(), to: @__nzdo__base

      defdelegate id(ref), to: @__nzdo__base
      defdelegate ref(ref), to: @__nzdo__base
      defdelegate sref(ref), to: @__nzdo__base
      defdelegate entity(ref, options \\ nil), to: @__nzdo__base
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__base
      defdelegate record(ref, options \\ nil), to: @__nzdo__base
      defdelegate record!(ref, options \\ nil), to: @__nzdo__base

      defdelegate __indexing__(), to: @__nzdo__base
      defdelegate __indexing__(setting), to: @__nzdo__base

      defdelegate __persistence__(setting \\ :all), to: @__nzdo__base
      defdelegate __persistence__(selector, setting), to: @__nzdo__base

      defdelegate __nmid__(), to: @__nzdo__base
      defdelegate __nmid__(setting), to: @__nzdo__base

      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :index)
      def __noizu_info__(:type), do: :index
      defdelegate __noizu_info__(report), to: @__nzdo__base
    end
  end

  def expand_indexes(nil, _base), do: %{}
  def expand_indexes([], _base), do: %{}
  def expand_indexes(indexes, base) do
    Enum.map(indexes, &(expand_index(&1, base)))
    |> Enum.filter(&(&1))
    |> Map.new()
  end

  def expand_index(l, base) do
    case l do
      {{:inline, type}, options} when is_list(options) or is_map(options) -> inline_indexer(base, type, options)
      {[{:inline, type}], options} when is_list(options) or is_map(options) -> inline_indexer(base, type, options)
      [{:inline, type}] when is_atom(type) -> inline_indexer(base, type, [])
      {:inline, type} when is_atom(type) -> inline_indexer(base, type, [])
      {indexer, options} when is_atom(indexer) and is_map(options) -> {indexer, %{options: options, fields: %{}}}
      {indexer, options} when is_atom(indexer) and is_list(options) -> {indexer, %{options: Map.new(options), fields: %{}}}
      indexer when is_atom(indexer) -> {indexer, %{options: %{}, fields: %{}}}
      _ -> raise "Invalid @index annotation #{inspect l}"
    end
  end

  def inline_indexer(base, type, options) when is_list(options) do
    indexer = domain_object_indexer(base)
    cond do
      Module.open?(base) -> Module.put_attribute(base, :__nzdo__inline_index, true)
      :else -> raise "Inline Index not possible when base Module is closed"
    end
    {indexer, %{options: Map.new(put_in(options, [:indexer], type)), fields: %{}}}
  end
  def inline_indexer(base, type, options) when is_map(options) do
    indexer = domain_object_indexer(base)
    cond do
      Module.open?(base) -> Module.put_attribute(base, :__nzdo__inline_index, true)
      :else -> raise "Inline Index not possible when base Module is closed"
    end
    {indexer, %{option: put_in(options, [:indexer], type), fields: %{}}}
  end

  def domain_object_indexer(base) when is_atom(base) do
    Module.concat([base, "Index"])
  end

end
