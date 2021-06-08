defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.Default do

  def id(_, %{identifier: id}) do
    id
  end
  def id(_, _ref) do
    nil
  end
  def ref(_, _ref) do
    nil
  end
  def sref(_, _ref) do
    nil
  end
  def entity(_, _ref, _options) do
    nil
  end
  def entity!(_, _ref, _options) do
    nil
  end
  def record(_, _ref, _options) do
    nil
  end
  def record!(_, _ref, _options) do
    nil
  end

  def sync(m, entity, record, context, options), do: nil

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

  defmacro __before_compile__(_env) do
    quote do

     #-----------------------------------
     # ERP
     #-----------------------------------
     def id(ref), do: @provider.id(__MODULE__, ref)
     def ref(ref), do: @provider.ref(__MODULE__, ref)
     def sref(ref), do: @provider.sref(__MODULE__, ref)
     def entity(ref, options \\ nil), do: @provider.entity(__MODULE__, ref, options)
     def entity!(ref, options \\ nil), do: @provider.entity!(__MODULE__, ref, options)
     def record(ref, options \\ nil), do: @provider.record(__MODULE__, ref, options)
     def record!(ref, options \\ nil), do: @provider.record!(__MODULE__, ref, options)

     #-----------------------------------
     #
     #-----------------------------------
     @entity_field_type_map ((@entity_field_types || []) |> Map.new())
     @entity_field_list (Enum.map(@entity_fields, fn({k,_}) -> k end) -- [:initial, :meta])

     def vsn(), do: @vsn
     def erp_handler(), do: __MODULE__
     def repo(), do: @repo
     def sref_module(), do: @sref_module
     def field_types(), do: @entity_field_type_map
     def fields(), do: @entity_field_list |> Enum.reverse()


     #=============================================================================
     # Noizu.MySQL.Entity Methods
     #=============================================================================
     def sync(entity, record, context, options \\ nil), do: @provider.sync(__MODULE__, entity, record, context, options)

     @layers Enum.map(@persistence_layer_settings.layers, fn(layer) -> {layer.layer, layer} end) |> Map.new()
     def persistence_layer(s), do: @layers[s]
     def persistence_layers(), do: @persistence_layer_settings.layers
     def persistence_settings(), do: @persistence_layer_settings

     if (@persistence_layer_settings.ecto_entity) do
       def mysql_entity?(), do: true

       if Module.get_attribute(__MODULE__, :mysql_identifier_field) do
         def mysql_identifier(ref), do: @provider.mysql_identifier(__MODULE__, ref)
       else
         def mysql_identifier(ref), do: id(ref)
       end


       def source(_), do: @persistence_layer_settings.ecto_entity

       if @persistence_layer_settings.universal? do
         def universal_identifier(ref), do: mysql_identifier(ref)
       else
         def universal_identifier(_ref), do: nil # TODO lookup from universal table
       end

       if @persistence_layer_settings.ref_module do
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


     if options = Module.get_attribute(@domain_object, :enum_values) do
       domain_object = @domain_object
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
       id: 1,
       ref: 1,
       sref: 1,
       entity: 1,
       entity: 2,
       entity!: 1,
       entity!: 2,
       record: 1,
       record: 2,
       record!: 1,
       record!: 2,
       fields: 0,
       field_types: 0,
       sync: 3,
       sync: 4,
       mysql_entity?: 0,
       mysql_identifier: 1,
       source: 1,
       universal_identifier: 1,



     ]

    end
  end

  def __after_compile__(env, _bytecode) do
    # Validate Generated Object
    :ok
  end

end
