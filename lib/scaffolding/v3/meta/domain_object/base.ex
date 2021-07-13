defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject do

  defmacro __before_compile__(_) do
    quote do

      @__nzdo__entity Module.get_attribute(__MODULE__, :__nzdo__entity)
      @__nzdo__struct Module.get_attribute(__MODULE__, :__nzdo__struct)

      defdelegate id(ref), to: @__nzdo__entity
      defdelegate ref(ref), to: @__nzdo__entity
      defdelegate sref(ref), to: @__nzdo__entity
      defdelegate entity(ref, options \\ nil), to: @__nzdo__entity
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record!(ref, options \\ nil), to: @__nzdo__entity

      @__nzdo__poly_settings  %{
        poly: @__nzdo__poly?,
        support: @__nzdo__poly_support,
        base: @__nzdo__poly_base
      }
      @__nzdo__meta__map Map.new(@__nzdo__meta || [])



      #################################################
      # __persistence__
      #################################################
      def vsn(), do: @vsn
      def __base__(), do: __MODULE__
      def __entity__(), do: @__nzdo__entity
      def __repo__(), do: @__nzdo__repo
      def __sref__(), do: @__nzdo__sref
      def __erp__(), do: @__nzdo__entity

      #################################################
      # __nmid__
      #################################################
      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all), do: @__nzdo__entity.__nmid__(:all)
      def __nmid__(:generator), do: @__nzdo__nmid_generator
      def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
      def __nmid__(:bare), do: @__nzdo__nmid_bare
      def __nmid__(:index), do: @__nzdo__entity.__noizu_info__(:nmid_index)

      #################################################
      # __indexing__
      #################################################
      defdelegate __indexing__(), to: @__nzdo__entity
      defdelegate __indexing__(setting), to: @__nzdo__entity

      #################################################
      # __persistence__
      #################################################
      defdelegate __persistence__(), to: @__nzdo__entity
      defdelegate __persistence__(setting), to: @__nzdo__entity
      defdelegate __persistence__(selector, setting), to: @__nzdo__entity

      #################################################
      # __noizu_info__
      #################################################
      def __noizu_info__(), do: __noizu_info__(:all)
      def __noizu_info__(:all) do
        Enum.map(
          [
            :type,
            :base,
            :entity,
            :struct,
            :repo,
            :sref,
            :restrict_provider,
            :poly,
            :json_configuration,
            :identifier_type,
            :fields,
            :field_attributes,
            :field_permissions,
            :field_types,
            :associated_types,
            :persistence,
            :indexing,
            :meta,
            :enum
          ],
          &({&1, __noizu_info__(&1)})
        )
      end
      def __noizu_info__(:type), do: :base
      def __noizu_info__(:base), do: __MODULE__
      def __noizu_info__(:entity), do: @__nzdo__entity
      def __noizu_info__(:struct), do: @__nzdo__entity
      def __noizu_info__(:repo), do: @__nzdo__repo
      def __noizu_info__(:sref), do: @__nzdo__sref
      def __noizu_info__(:restrict_provider), do: nil
      def __noizu_info__(:poly), do: @__nzdo__poly_settings
      @entity_driven_properties [
        :json_configuration,
        :identifier_type,
        :fields,
        :persisted_fields,
        :field_attributes,
        :field_permissions,
        :field_types,
        :associated_types
      ]
      def __noizu_info__(property) when property in @entity_driven_properties, do: @__nzdo__entity.__noizu_info__(property)
      def __noizu_info__(:persistence), do: __persistence__()
      def __noizu_info__(:indexing), do: __indexing__()
      def __noizu_info__(:meta), do: @__nzdo__meta__map
      def __noizu_info__(:enum), do: __enum__()

      #################################################
      # __fields__
      #################################################
      defdelegate __fields__, to: @__nzdo__entity
      defdelegate __fields__(setting), to: @__nzdo__entity

      #################################################
      # __enum__
      #################################################
      def __enum__(), do: __enum__(:all)
      def __enum__(:all) do
        Enum.map([:list, :default, :is_enum_table, :value_type, :type], &({&1, __enum__(&1)}))
      end
      def __enum__(:list), do: @__nzdo__enum_list
      def __enum__(:default), do: @__nzdo__enum_default_value
      def __enum__(:is_enum?), do: @__nzdo__enum_table
      def __enum__(:value_type), do: @__nzdo__enum_ecto_type
      def __enum__(:type), do: @__nzdo__enum_type

      #################################################
      # __json__
      #################################################
      def __json__(), do: __json__(:all)
      def __json__(:all) do
        Enum.map([:provider, :default, :formats, :white_list, :format_groups, :field_groups], &({&1, __json__(&1)}))
      end
      def __json__(:provider), do: @__nzdo__json_provider
      def __json__(:default), do: @__nzdo__json_format
      def __json__(:formats), do: @__nzdo__json_supported_formats
      def __json__(:white_list), do: @__nzdo__json_white_list
      def __json__(:format_groups), do: @__nzdo__json_format_groups
      def __json__(:field_groups), do: @__nzdo__json_field_groups

      #--------------------
      # EctoEnum
      #--------------------
      domain_object = __MODULE__
      has_list = Module.get_attribute(__MODULE__, :__nzdo__enum_list) || false

      @__nzdo__enum_type nil
      if Module.get_attribute(__MODULE__, :__nzdo__enum_list) do
        @__nzdo__enum_type Module.concat([__MODULE__, "Ecto.EnumType"])
      end

      if has_list do
        defmodule Ecto.EnumType do


          {values, default_value, ecto_type} = case Module.get_attribute(domain_object, :__nzdo__enum_list) do
                                                 {v, o} ->
                                                   {
                                                     v,
                                                     o[:default_value] || Module.get_attribute(domain_object , :__nzdo__enum_default_value) || :none,
                                                     o[:ecto_type] || Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                                   }
                                                 v when is_list(v) ->
                                                   {
                                                     v,
                                                     Module.get_attribute(domain_object, :__nzdo__enum_default_value) || :none,
                                                     Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                                   }
                                                 _ -> {nil, nil, nil}
                                               end

          Noizu.Ecto.EnumTypeBehaviour.__enum_type__(
            values: values,
            default: default_value,
            ecto_type: ecto_type
          )
        end

        def atoms(), do: @__nzdo__enum_type.atom_to_enum()
      end



      #--------------------
      # Ref
      #--------------------
      cond do
        Module.get_attribute(__MODULE__, :__nzdo_enum_ref) ->
          e = @__nzdo__entity
          b = __MODULE__
          defmodule Ecto.EnumReference do
            use Noizu.EnumRefBehaviour, entity: e, base: b
          end

        Module.get_attribute(__MODULE__, :__nzdo_universal_ref) ->
          e = @__nzdo__entity
          defmodule Ecto.UniversalReference do
            use Noizu.UniversalRefBehaviour, entity: e
          end

        Module.get_attribute(__MODULE__, :__nzdo_basic_ref) ->
          e = @__nzdo__entity
          defmodule Ecto.Reference do
            use Noizu.BasicRefBehaviour, entity: e
          end
        :else -> :ok
      end

      #--------------------
      # Index
      #--------------------
      if Module.has_attribute?(__MODULE__, :__nzdo__inline_index) && Module.get_attribute(__MODULE__, :__nzdo__inline_index) do
        e = @__nzdo__entity
        defmodule Index do
          require Noizu.DomainObject
          Noizu.DomainObject.noizu_index(entity: e, inline: true) do

          end
        end
      end

    end
  end

end
