defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider do
  def ecto_identifier(_, %{ecto_identifier: id}), do: id
  def ecto_identifier(_, %{identifier: id}) when is_integer(id), do: id
  def ecto_identifier(m, ref) do
    ref = m.ref(ref)
    case Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable.read!(ref) do
      %Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable{ecto_identifier: id} -> id
      _ ->
        case m.entity(ref) do
          %{ecto_identifier: id} ->
            Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable.write!(%Noizu.Scaffolding.V3.Database.EctoIdentifierLookupTable{identifier: ref, ecto_identifier: id})
            id
          _ -> nil
        end
    end
  end

  def universal_identifier_lookup(m, ref) do
    ref = m.ref(ref)
    case Noizu.Scaffolding.V3.Database.UniversalLookupTable.read!(ref) do
      %Noizu.Scaffolding.V3.Database.UniversalLookupTable{universal_identifier: id} -> id
    end
  end

  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__ecto_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultEctoProvider

      if (@__nzdo_persistence.ecto_entity) do
        #-----------------------
        #
        #-----------------------
       def ecto_entity?(), do: true

       #-----------------------
       #
       #-----------------------
       cond do
         Module.has_attribute?(__MODULE__, :__nzdo__ecto_identifier_field) ->
           def ecto_identifier(ref), do: @__nzdo__ecto_imp.ecto_identifier(__MODULE__, ref)
         Module.get_attribute(__MODULE__, :__nzdo__identifier_type) == :integer ->
           def ecto_identifier(ref), do: __MODULE__.id(ref)
         :else ->
           def ecto_identifier(_), do: throw "#{__MODULE__} implementer must provide a ecto_identifier method (non integer identifier, no mysql_identifer field)"
       end

       #-----------------------
       #
       #-----------------------
       def source(_), do: @__nzdo_persistence.ecto_entity

       cond do
         @__nzdo_persistence.options[:universal_identifier] ->
           def universal_identifier(ref), do: __MODULE__.id(ref)
         @__nzdo_persistence.options[:universal_lookup] ->
           def universal_identifier(ref), do: @__nzdo__ecto_imp.universal_identifier_lookup(__MODULE__, ref)
         :else ->
           def universal_identifier(_), do: throw "#{__MODULE__} does not support universal_identifier syntax"
       end

       if v = @__nzdo_persistence.options[:generate_reference_type] do
         cond do
           v == :enum_ref ->
             Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
           v == :basic_ref ->
             Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
           v == :universal_ref ->
             Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
           @__nzdo_persistence.options[:universal_reference] == false && @__nzdo_persistence.options[:enum_table] ->
             Module.put_attribute(@__nzdo__base, :__nzdo_enum_ref, true)
           @__nzdo_persistence.options[:universal_reference] || @__nzdo_persistence.options[:universal_lookup] ->
             Module.put_attribute(@__nzdo__base, :__nzdo_universal_ref, true)
           :else ->
               Module.put_attribute(@__nzdo__base, :__nzdo_basic_ref, true)
         end
       end

     else
       def ecto_entity?(), do: false
       def ecto_identifier(_), do: nil
       def source(_), do: nil
       def universal_identifier(_), do: nil
     end

     if options = Module.get_attribute(@__nzdo__base, :enum_list) do
       Module.put_attribute(@__nzdo__base, :__nzdo_enum_field, options)
     end

     defoverridable [
       ecto_entity?: 0,
       ecto_identifier: 1,
       source: 1,
       universal_identifier: 1,
     ]

    end
  end
end
