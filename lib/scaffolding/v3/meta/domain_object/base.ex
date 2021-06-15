defmodule Noizu.ElixirScaffolding.V3.Meta.DomainObject do

  defmacro __before_compile__(_) do
    quote do
      defdelegate id(ref), to: @__nzdo__entity
      defdelegate ref(ref), to: @__nzdo__entity
      defdelegate sref(ref), to: @__nzdo__entity
      defdelegate entity(ref, options \\ nil), to: @__nzdo__entity
      defdelegate entity!(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record(ref, options \\ nil), to: @__nzdo__entity
      defdelegate record!(ref, options \\ nil), to: @__nzdo__entity
      defdelegate __noizu_record__(type, ref, options \\ nil), to: @__nzdo__entity



      @__nzdo__poly_settings  %{
        poly: @__nzdo__poly?,
        support: @__nzdo__poly_support,
        base: @__nzdo__poly_base
      }

      @__nzdo__meta__map Map.new(@__nzdo__meta || [])


      def vsn(), do: @vsn
      def __entity__(), do: @__nzdo__entity
      def __repo__(), do: @__nzdo__repo
      def __sref__(), do: @__nzdo__sref
      def __erp__(), do: @__nzdo__entity


      def __nmid__(), do: __nmid__(:all)
      def __nmid__(:all), do: @__nzdo__entity.__nmid__(:all)
      def __nmid__(:generator), do: @__nzdo__nmid_generator
      def __nmid__(:sequencer), do: @__nzdo__nmid_sequencer
      def __nmid__(:bare), do: @__nzdo__nmid_bare
      def __nmid__(:index), do: @__nzdo__entity.__noizu_info__(:nmid_index)

      defdelegate __persistence__(setting \\ :all), to:  @__nzdo__entity
      defdelegate __persistence__(selector, setting), to:  @__nzdo__entity

      def __noizu_info__(:type), do: :base
      def __noizu_info__(:base), do: __MODULE__
      def __noizu_info__(:entity), do: @__nzdo__entity
      def __noizu_info__(:repo), do: @__nzdo__repo
      def __noizu_info__(:sref), do: @__nzdo__sref
      def __noizu_info__(:restrict_provider), do: nil
      def __noizu_info__(:poly), do: @__nzdo__poly_settings
      def __noizu_info__(:json_configuration), do: @__nzdo__entity.__noizu_info__(:json_configuration)
      def __noizu_info__(:identifier_type), do: @__nzdo__entity.__noizu_info__(:identifier_type)
      def __noizu_info__(:fields), do: @__nzdo__entity.__noizu_info__(:fields)
      def __noizu_info__(:field_attributes), do: @__nzdo__entity.__noizu_info__(:field_attributes)
      def __noizu_info__(:field_types), do: @__nzdo__entity.__noizu_info__(:field_types)
      def __noizu_info__(:persistence), do: @__nzdo__entity.__noizu_info__(:persistence)
      def __noizu_info__(:associated_types), do: @__nzdo__entity.__noizu_info__(:associated_types)
      def __noizu_info__(:meta), do: @__nzdo__meta__map



      #--------------------
      # UniversalRef
      #--------------------
      if Module.get_attribute(__MODULE__, :__nzdo_universal_ref) do
        m = @__nzdo__entity
        defmodule UniversalRef do
          use Noizu.UniversalRefBehaviour, entity: m
        end
      end

      #--------------------
      # EnumType
      #--------------------
      if options = Module.get_attribute(__MODULE__, :__nzdo__enum_list) do
        domain_object = __MODULE__
        defmodule EnumField do
          {values,default_value,ecto_type} = case options do
                                               {v,options} ->
                                                 {v,
                                                   options[:default_value] || Module.get_attribute(domain_object, :__nzdo__enum_default_value) || :none,
                                                   options[:ecto_type] || Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                                 }
                                               v when is_list(v) ->
                                                 {v,
                                                   Module.get_attribute(domain_object, :__nzdo__enum_default_value) || :none,
                                                   Module.get_attribute(domain_object, :__nzdo__enum_ecto_type) || :integer
                                                 }
                                             end
          use Noizu.EnumFieldBehaviour,
              values: values,
              default: default_value,
              ecto_type: ecto_type
        end
      end
    end
  end

end
