defmodule Noizu.DomainObject do

  defmacro __using__(options \\ nil) do
    nmid_generator = options[:nmid_generator]
    nmid_sequencer = options[:nmid_sequencer]
    nmid_index = options[:nmid_index]
    auto_generate = options[:auto_generate]
    caller = __CALLER__
    quote do
      import Noizu.DomainObject, only: [file_rel_dir: 1]
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :json_white_list, accumulate: false)
      Module.register_attribute(__MODULE__, :json_format_group, accumulate: true)
      Module.register_attribute(__MODULE__, :json_field_group, accumulate: true)

      # Insure only referenced once.
      if line = Module.get_attribute(__MODULE__, :__nzdo__base_definied) do
        raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} duplicate use Noizu.DomainObject reference. First defined on #{elem(line,0)}:#{elem(line,1)}"
      end
      @__nzdo__base_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

      if v = unquote(nmid_generator) do
        Module.put_attribute(__MODULE__, :nmid_generator, v)
      end
      if v = unquote(nmid_sequencer) do
        Module.put_attribute(__MODULE__, :nmid_sequencer, v)
      end
      if v = unquote(nmid_index) do
        Module.put_attribute(__MODULE__, :nmid_index, v)
      end
      if unquote(auto_generate) != nil do
        Module.put_attribute(__MODULE__, :auto_generate, unquote(auto_generate))
      end
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_entity(options \\ [], [do: block]) do
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_sphinx(options \\ [], [do: block]) do
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Sphinx.__noizu_sphinx(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_struct(options \\ [], [do: block]) do
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Struct.__noizu_struct__(__CALLER__, options, block)
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_repo(options \\ [], [do: block]) do
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
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

  #--------------------------------------------
  #
  #--------------------------------------------
  defdelegate expand_persistence_layers(layers, module), to: Noizu.ElixirScaffolding.V3.Meta.Persistence

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro extract_transform_attribute(attribute, setting, mfa, default \\ nil) do
    quote do
      cond do
        v = Module.get_attribute(__MODULE__,unquote(attribute)) ->
          {m,f,a} = unquote(mfa)
          apply(m,f, [v] ++ a)
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info(unquote(setting)) -> @__nzdo__base.__noizu_info(unquote(setting))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__base, unquote(attribute))
          {m,f,a} = unquote(mfa)
          apply(m,f, [v] ++ a)
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info(unquote(setting)) -> @__nzdo__poly_base.__noizu_info(unquote(setting))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) ->
          v = Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
          {m,f,a} = unquote(mfa)
          apply(m,f, [v] ++ a)
        :else ->
          v = unquote(default)
          {m,f,a} = unquote(mfa)
          apply(m,f, [v] ++ a)
      end
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro extract_has_attribute(attribute, default) do
    quote do
      cond do
        Module.has_attribute?(__MODULE__,unquote(attribute)) -> Module.get_attribute(__MODULE__,unquote(attribute))
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info(unquote(attribute)) -> @__nzdo__base.__noizu_info(unquote(attribute))
        @__nzdo__base_open? && Module.has_attribute?(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info(unquote(attribute)) -> @__nzdo__poly_base.__noizu_info(unquote(attribute))
        @__nzdo__poly_base_open? && Module.has_attribute?(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro extract_attribute(attribute, default) do
    quote do
      cond do
        v = Module.get_attribute(__MODULE__,unquote(attribute)) -> v
        !@__nzdo__base_open? && @__nzdo__base.__noizu_info(unquote(attribute)) -> @__nzdo__base.__noizu_info(unquote(attribute))
        @__nzdo__base_open? && Module.get_attribute(@__nzdo__base, unquote(attribute)) -> Module.get_attribute(@__nzdo__base, unquote(attribute))
        !@__nzdo__poly_base_open? && @__nzdo__poly_base.__noizu_info(unquote(attribute)) -> @__nzdo__poly_base.__noizu_info(unquote(attribute))
        @__nzdo__poly_base_open? && Module.get_attribute(@__nzdo__poly_base, unquote(attribute)) -> Module.get_attribute(@__nzdo__poly_base, unquote(attribute))
        :else -> unquote(default)
      end
    end
  end

end
