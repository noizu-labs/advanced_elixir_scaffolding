defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider do
  def mysql_identifier(_, %{mysql_identifier: id}), do: id
  def mysql_identifier(_, %{identifier: id}), do: id
  def mysql_identifier(m, ref) do
    ref = m.ref(ref)
    case Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable.read!(ref) do
      %Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable{mysql_identifier: id} -> id
      _ ->
        case m.entity(ref) do
          %{mysql_identifier: id} ->
            Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable.write!(%Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable{identifier: ref, mysql_identifier: id})
            id
          %{identifier: id} ->
            Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable.write!(%Noizu.Scaffolding.V3.Database.MySQLIdentifierLookupTable{identifier: ref, mysql_identifier: id})
            id
          _ -> nil
        end
    end
  end


  defmacro __using__(options \\ nil) do
    quote do
      @__nzdo__ecto_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider

      if (@__nzdo_persistence.ecto_entity) do

        #-----------------------
        #
        #-----------------------
       def mysql_entity?(), do: true

       #-----------------------
       #
       #-----------------------
       if Module.get_attribute(__MODULE__, :__nzdo__has_mysql_field) do
         def mysql_identifier(ref), do: @__nzdo__ecto_imp.mysql_identifier(__MODULE__, ref)
       else
         def mysql_identifier(ref), do: id(ref)
       end

       #-----------------------
       #
       #-----------------------
       def source(_), do: @__nzdo_persistence.ecto_entity

       if @__nzdo_persistence.universal? do
         def universal_identifier(ref), do: mysql_identifier(ref)
       else
         def universal_identifier(_ref), do: nil # TODO lookup from universal table
       end

       if @__nzdo_persistence.ref_module do
         m = __MODULE__
         defmodule UniversalRef do
           use Noizu.UniversalRefBehaviour, entity: m
         end
       end

     else
       def mysql_entity?(), do: false
       def mysql_identifier(ref), do: nil
       def source(_), do: nil
       def universal_identifier(ref), do: nil
     end


     if options = Module.get_attribute(@__nzdo__base, :enum_values) do
       domain_object = @__nzdo__base
       defmodule EnumField do
         {values,default_value,type} = case options do
                    {v,options} ->
                      {v,
                        options[:default] || Module.get_attribute(domain_object, :enum_values_default) || :none,
                        options[:ecto_type] || Module.get_attribute(domain_object, :enum_values_ecto_type) || :integer
                      }
                      v when is_list(v) ->
                        {v,
                          Module.get_attribute(domain_object, :enum_values_default) || :none,
                          Module.get_attribute(domain_object, :enum_values_ecto_type) || :integer
                        }
                  end
         use Noizu.EnumFieldBehaviour,
             values: values,
             default: default_value,
             ecto_type: type
       end
     end

     defoverridable [
       mysql_entity?: 0,
       mysql_identifier: 1,
       source: 1,
       universal_identifier: 1,
     ]

    end
  end
end
