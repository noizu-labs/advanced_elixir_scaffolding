defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject.Struct do



  def __noizu_struct__(caller, options, block) do
    vsn = options[:vsn]
    process_config = quote do
                       import Noizu.DomainObject, only: [file_rel_dir: 1]

                       #---------------------
                       # Insure Single Call
                       #---------------------
                       if line = Module.get_attribute(__MODULE__, :__nzdo__struct_definied) do
                         raise "#{file_rel_dir(unquote(caller.file))}:#{unquote(caller.line)} attempting to redefine #{__MODULE__}.noizu_struct first defined on #{elem(line,0)}:#{elem(line,1)}"
                       end
                       @__nzdo__struct_definied {file_rel_dir(unquote(caller.file)), unquote(caller.line)}

                       #---------------------
                       # Registerss
                       #---------------------
                       Module.register_attribute(__MODULE__, :__nzdo__derive, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__fields, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_permissions, accumulate: true)
                       Module.register_attribute(__MODULE__, :__nzdo__field_types, accumulate: true)

                       #---------------------
                       # Settings
                       #---------------------
                       @vsn (cond do
                               v = unquote(vsn) -> v
                               v = Module.get_attribute(__MODULE__, :vsn) -> v
                             end)




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
                       # fields meta data
                       #----------------------
                       @__nzdo__field_types_map ((@__nzdo__field_types || []) |> Map.new())
                       @__nzdo__field_list (Enum.map(@__nzdo__fields, fn({k,_}) -> k end))

                       #----------------------
                       # Universals Fields (always include)
                       #----------------------
                       Module.put_attribute(__MODULE__, :__nzdo_fields, {:vsn, @vsn})

                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields
               end

    quote do
      unquote(process_config)
      unquote(generate)
      @before_compile Noizu.ElixirScaffolding.V3.Meta.DomainObject.Struct
    end
  end

  defmacro __before_compile__(_) do
    quote do

      def vsn(), do: @vsn

      def __noizu_info__(:fields), do: @__nzdo__entity.__noizu_info__(:fields)
      def __noizu_info__(:field_types), do: @__nzdo__entity.__noizu_info__(:field_types)
      @__nzdo__meta__map Map.new(@__nzdo__meta || [])
      def __noizu_info__(:meta), do: @__nzdo__meta__map
    end
  end

end
