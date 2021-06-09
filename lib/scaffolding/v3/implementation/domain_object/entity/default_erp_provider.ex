defmodule Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider do

  #-----------------
  # id
  #-----------------
  def id(m, {:ref, m, id}), do: id
  def id(m, ref) do
    r = ref && m.ref(ref)
    r && (r != ref) && m.id(r) || nil
  end

  #------------------
  #
  #------------------
  def ref(_, nil), do: nil
  def ref(m, %{__struct__: m, identifier: id}), do: {:ref, m, id}
  def ref(m, ref), do: m.valid_identifier(ref) && {:ref, m, ref}

  #------------------
  #
  #------------------
  def sref(m, {:ref, m, id}) do
    sid = m.identifier_to_string(id)
    m.__sref_prefix__() <> sid
  end
  def sref(m, ref) do
    r = ref && m.ref(ref)
    r && (r != ref) && m.sref(r) || nil
  end

  # entity load
  def entity(m, %{__struct__: m} = ref, _), do: ref
  def entity(_, _ref, _options) do
    nil
  end
  def entity!(m, %{__struct__: m} = ref, _), do: ref
  def entity!(_, _ref, _options) do
    nil
  end
  def record(_, _ref, _options) do
    nil
  end
  def record!(_, _ref, _options) do
    nil
  end

  def __noizu_record__(__MODULE__, type, ref, options) do

  end

  #-----------------------------------
  #
  #-----------------------------------
  def sref_section_regex(_, :integer), do: "([0-9]*)"
  def sref_section_regex(_, :string), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(_, :hash), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(_, :uuid), do: "([0-9a-zA-Z_-]*)"
  def sref_section_regex(m, {:list, template}), do: "(\[((" <> m.sref_section_regex(template) <> ",?)+)\])"
  def sref_section_regex(m, {:compound, template, _}), do: m.sref_section_regex({:compound, template})
  def sref_section_regex(m, {:compound, template}), do: "(\{" <> Enum.join(Enum.map(template, &(m.sref_section_regex(&1))), ",")  <>  "\})"
  def sref_section_regex(m, {:atom, _c}), do: m.sref_section_regex(:atom)
  def sref_section_regex(_, :atom), do: "([a-z_A-Z0-9]*)"
  def sref_section_regex(m, {:ref, _c}), do: m.sref_section_regex(:ref)
  def sref_section_regex(_, :ref), do: "(ref\.[a-z0-9\-]+\{[a-z_\-0-9@,.]+\}|ref\.[a-z0-9\-]+\.[a-z_\-0-9@.]+)"

  #-----------------------------------
  #
  #-----------------------------------
  def id_to_string(_m, _, nil), do: nil
  def id_to_string(_m, :integer, id) when is_integer(id), do: Integer.to_string(id)
  def id_to_string(_m, :string, id) when is_bitstring(id), do: id
  def id_to_string(_m, :hash, id) when is_bitstring(id), do: id
  def id_to_string(_m, :uuid, id), do: UUID.binary_to_string!(id)
  def id_to_string(m, {:list, template}, id) do
    "[" <> (Enum.map(id, &(m.id_to_string(template, &1))) |> Enum.join(",")) <> "]"
  end
  def id_to_string(m, {:compound, template, prep}, id) do
    case prep do
      prep when is_function(prep, 2) -> m.id_to_string({:compound, template}, prep.(:encode, id))
      {m,f} -> m.id_to_string({:compound, template}, apply(m, f, [:encode, id]))
      _ -> throw "invalid compound id formatter"
    end
  end
  def id_to_string(m, {:compound, template}, id) do
      template_list = Tuple.to_list(template)
      id_list = Tuple.to_list(id)
      length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
      l = Enum.map_reduce(id_list, 0, &( {m.id_to_string(Enum.at(template_list, &2), &1), &2 + 1}))
      "{" <> Enum.join(l, ",") <> "}"
  end
  def id_to_string(_m, :atom, id), do: Atom.to_string(id)
  def id_to_string(_m, {:atom, :existing}, id), do: Atom.to_string(id)
  def id_to_string(_m, {:atom, constraint}, id) do
    sref = case constraint do
      v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
      v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
      v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
      v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
      {m,f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
      _ -> throw "invalid atom constraint #{inspect constraint}"
    end
    "[#{sref}]"
  end
  def id_to_string(_m, :ref, id), do: Noizu.ERP.sref(id) || throw "invalid ref"
  def id_to_string(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    case constraint do
      v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
      {m,f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
      _ -> throw "invalid ref constraint #{inspect constraint}"
    end
  end

  #-----------------------------------
  #
  #-----------------------------------
  def string_to_id(_m, _, nil), do: nil
  def string_to_id(_m, _, id) when not is_bitstring(id), do: throw "invalid sref id part #{inspect id}"
  def string_to_id(_m, :integer, id), do: String.to_integer(id)
  def string_to_id(_m, :string, id), do: id
  def string_to_id(_m, :hash, id), do: id
  def string_to_id(_m, :uuid, id), do: UUID.string_to_binary!(id)
  def string_to_id(m, {:list, template}, id) do
      r = Regex.compile(m.sref_section_regex(template))
      case Regex.split(r, id, :include_captures) do
        v when is_list(v) and length(v) > 0 ->
          Enum.filter(v, &(!Enum.member?(["[", ",", "]"], &1)) )
          |> Enum.map(&(m.string_to_id(template, &1)))
        _ -> throw "invalid sref id part #{inspect id}"
      end
  end
  def string_to_id(m, {:compound, template, prep}, id) do
    formatted = m.string_to_id({:compound, template}, id)
    case prep do
      prep when is_function(prep, 2) -> prep.(:decode, formatted)
      {m,f} -> apply(m, f, [:decode, formatted])
      _ -> throw "invalid compound id formatter"
    end
  end
  def string_to_id(m, {:compound, template}, id) do
    template_list = Tuple.to_list(template)
    id_list = Tuple.to_list(id)
    length(template_list) != length(id_list) && throw "invalid compound id #{inspect id}"
    extract = Enum.map(template, &(m.sref_section_regex(&1)))
              |> Enum.join(",")
    extract = Regex.compile("^{" <> extract <> "}")
    case Regex.run(extract, id) do
      nil -> throw "vinalid compind id #{extract.source}"
      [] -> throw "vinalid compind id #{extract.source}"
      v when is_list(v) ->
        length(v) != length(template_list) && throw "malformed compound id: #{inspect id}"
        Enum.map(v, &(m.string_to_id(Enum.at(template_list, &2), &1))) |> List.to_tuple()
    end
  end
  def string_to_id(_m, :atom, id), do: Atom.to_string(id)
  def string_to_id(_m, {:atom, :existing}, id), do: Atom.to_string(id)
  def string_to_id(_m, {:atom, constraint}, id) do
    sref = case constraint do
             v when is_list(v) -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v = %MapSet{} -> Enum.member?(v, id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 0) -> v.()[id] && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             v when is_function(v, 1) -> v.(id) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             {m,f} -> apply(m, f, [id]) && Atom.to_string(id) || throw "unsupported atom id #{inspect id}"
             _ -> throw "invalid atom constraint #{inspect constraint}"
           end
    "[#{sref}]"
  end
  def string_to_id(_m, :ref, id), do: Noizu.ERP.sref(id) || throw "invalid ref"
  def string_to_id(_m, {:ref, constraint}, id) do
    m = case Noizu.ERP.ref(id) do
          {:ref, m, _} -> m
          _else -> throw "invalid ref"
        end
    sref = Noizu.ERP.sref(id) || throw "invalid ref"
    case constraint do
      v when is_list(v) -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v = %MapSet{} -> Enum.member?(v, m) && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 0) -> v.()[m] && sref || throw "unsupported ref id #{inspect sref}"
      v when is_function(v, 1) -> v.(m) && sref || throw "unsupported ref id #{inspect sref}"
      {m,f} -> apply(m, f, [m]) && sref || throw "unsupported ref id #{inspect sref}"
      _ -> throw "invalid ref constraint #{inspect constraint}"
    end
  end






  defmacro __using__(_options \\ nil) do
    quote do
      @__nzdo__erp_imp Noizu.ElixirScaffolding.V3.Implementation.DomainObject.Entity.DefaultErpProvider
      #-----------------------------------
      #
      #-----------------------------------
      def __sref_prefix__, do: "ref.#{@__nzdo__sref}."

      def valid_identifier(), do: true

      #-----------------------------------
      # ERP
      #-----------------------------------
      # id
      #-----------------
      def id("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.id(__MODULE__.ref(ref))
      def id(ref), do: @__nzdo__erp_imp.id(__MODULE__, ref)
      # ref
      #-----------------
      def ref("ref.#{@__nzdo__sref}{" <> id) do
        identifier = string_to_id(String.slice(id, 0..-2))
        identifier && {:ref, __MODULE__, identifier}
      end
      def ref("ref.#{@__nzdo__sref}." <> id) do
        identifier = string_to_id(id)
        identifier && {:ref, __MODULE__, identifier}
      end
      def ref(ref), do: @__nzdo__erp_imp.ref(__MODULE__, ref)
      # sref
      #-----------------
      def sref("ref.#{@__nzdo__sref}" <> _ = ref), do: ref
      def sref(ref), do: @__nzdo__erp_imp.sref(__MODULE__, ref)
      # entity
      #-----------------
      def entity("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity(__MODULE__.ref(ref))
      def entity(ref, options \\ nil), do: @__nzdo__erp_imp.entity(__MODULE__, ref, options)
      # entity!
      #-----------------
      def entity!("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.entity!(__MODULE__.ref(ref))
      def entity!(ref, options \\ nil), do: @__nzdo__erp_imp.entity!(__MODULE__, ref, options)
      # record
      #-----------------
      def record("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.record(__MODULE__.ref(ref))
      def record(ref, options \\ nil), do: @__nzdo__erp_imp.record(__MODULE__, ref, options)
      # record!
      #-----------------
      def record!("ref.#{@__nzdo__sref}" <> _ = ref), do: __MODULE__.record!(__MODULE__.ref(ref))
      def record!(ref, options \\ nil), do: @__nzdo__erp_imp.record!(__MODULE__, ref, options)

      #---------------------
      #
      #---------------------
      def __noizu_record__(type, ref, options \\ nil), do: @__nzdo__erp_imp.__noizu_record__(__MODULE__, type, ref, options)
      def sref_section_regex(type), do: @__nzdo__erp_imp.sref_section_regex(__MODULE__, type)

      def id_to_string(type, id), do: @__nzdo__erp_imp.id_to_string(__MODULE__, type, id)
      def id_to_string(id), do: @__nzdo__erp_imp.id_to_string(__MODULE__, @__nzdo__identifier_type, id)

      def string_to_id(id), do: @__nzdo__erp_imp.string_to_id(__MODULE__, @__nzdo__identifier_type, id)
      def string_to_id(type, id), do: @__nzdo__erp_imp.string_to_id(__MODULE__, type, id)

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
        sref_section_regex: 1,
        id_to_string: 1,
        id_to_string: 2,
        string_to_id: 1,
        string_to_id: 2,
      ]
    end
  end

end
