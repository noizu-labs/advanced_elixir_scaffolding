defmodule Noizu.AdvancedScaffolding.SimpleObject do

  defmacro __using__(options \\ nil) do
    nmid_generator = options[:nmid_generator]
    nmid_sequencer = options[:nmid_sequencer]
    nmid_index = options[:nmid_index]
    auto_generate = options[:auto_generate]
    caller = __CALLER__
    quote do
      import Noizu.AdvancedScaffolding.DomainObject, only: [file_rel_dir: 1]
      require Noizu.AdvancedScaffolding.SimpleObject
      Module.register_attribute(__MODULE__, :index, accumulate: true)
      Module.register_attribute(__MODULE__, :persistence_layer, accumulate: true)
      Module.register_attribute(__MODULE__, :__nzdo__meta, accumulate: false)
      Module.register_attribute(__MODULE__, :json_white_list, accumulate: false)
      Module.register_attribute(__MODULE__, :json_format_group, accumulate: true)
      Module.register_attribute(__MODULE__, :json_field_group, accumulate: true)

      # Insure only referenced once.
      if line = Module.get_attribute(__MODULE__, :__nzdo__simple_definied) do
        raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} duplicate use Noizu.AdvancedScaffolding.SimpleObject reference. First defined on #{elem(line, 0)}:#{elem(line, 1)}"
      end
      @__nzdo__simple_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

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
    end
  end

  #--------------------------------------------
  #
  #--------------------------------------------
  defmacro noizu_struct(options \\ [], [do: block]) do
    Noizu.AdvancedScaffolding.Meta.SimpleObject.Struct.__noizu_struct__(__CALLER__, options, block)
  end

end
