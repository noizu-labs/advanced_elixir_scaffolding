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
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       import Noizu.DomainObject, only: [file_rel_dir: 1]
                       import Noizu.ElixirCore.Guards
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       if line = Module.get_attribute(__MODULE__, :__nzdo__index_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_index first defined on #{elem(line, 0)}:#{
                           elem(line, 1)
                         }"
                       end
                       @__nzdo__index_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Find Base
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       @__nzdo__base Module.split(__MODULE__)
                                     |> Enum.slice(0..-2)
                                     |> Module.concat()
                       if !Module.get_attribute(@__nzdo__base, :__nzdo__base_definied) do
                         raise "#{@__nzdo__base} must include use Noizu.DomainObject call."
                       end

                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       try do
                         import Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index
                         unquote(block)
                       after
                         :ok
                       end
                     end

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(process_config)
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use unquote(indexer)

      # Post User Logic Hook and checks.
      #@before_compile unquote(internal_provider)
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Index
      #@after_compile unquote(internal_provider)
      @file __ENV__.file
    end
  end



  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro __before_compile__(_) do
    quote do

      def vsn(), do: @__nzdo__base.vsn()
      def __base__(), do: @__nzdo__base
      def __entity__(), do: @__nzdo__base.__entity__()
      def __repo__(), do: @__nzdo__base.__repo__()
      def __sref__(), do: @__nzdo__base.__sref__()
      def __erp__(), do: @__nzdo__base.__erp__()

      def id(ref), do: @__nzdo__base.id(ref)
      def ref(ref), do: @__nzdo__base.ref(ref)
      def sref(ref), do: @__nzdo__base.sref(ref)
      def entity(ref, options \\ nil), do: @__nzdo__base.entity(ref, options)
      def entity!(ref, options \\ nil), do: @__nzdo__base.entity!(ref, options)
      def record(ref, options \\ nil), do: @__nzdo__base.record(ref, options)
      def record!(ref, options \\ nil), do: @__nzdo__base.record!(ref, options)

      def __indexing__(), do: @__nzdo__base.__indexing__()
      def __indexing__(setting), do: @__nzdo__base.__indexing__(setting)

      def __persistence__(setting \\ :all), do: @__nzdo__base.__persistence__(setting)
      def __persistence__(selector, setting), do: @__nzdo__base.__persistence__(selector, setting)

      def __nmid__(), do: @__nzdo__base.__nmid__()
      def __nmid__(setting), do: @__nzdo__base.__nmid__(setting)

      def __noizu_info__(), do: put_in(@__nzdo__base.__noizu_info__(), [:type], :index)
      def __noizu_info__(:type), do: :index
      def __noizu_info__(report), do: @__nzdo__base.__noizu_info__(report)
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
