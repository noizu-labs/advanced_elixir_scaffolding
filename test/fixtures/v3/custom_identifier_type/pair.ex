defmodule Noizu.AdvancedScaffolding.Test.Fixture.V3.Pair.CustomIdentifierType do
  @behaviour Noizu.DomainObject.IdentifierTypeBehaviour
  

  def __noizu_info__(:type), do: :identifier_type
  def type(), do: :pair
  
  def __valid_identifier__(identifier, _) do
    case identifier do
      {_, _} -> :ok
      _ -> {:error, {:identifier, :not_tuple_of_2}}
    end
  end
  
  def __sref_section_regex__(_c), do: {:ok, "[a-zA-Z_-0-9\.]+,[a-zA-Z_-0-9\.]+"}
  
  def __id_to_string__(nil, _c), do: {:error, {:identifier, :is_nil}}
  def __id_to_string__({a,b}, _c) , do: {:ok, "#{a},#{b}"}
  def __id_to_string__(identifier, _c), do: {:error, {:invalid_identifier, identifier}}
  
  def __string_to_id__(identifier, _c) when not is_bitstring(identifier), do: {:error, {:serialized_identifier, :not_string, identifier}}
  def __string_to_id__(identifier, _c) do
    case String.split(identifier, ",") do
      [a,b] -> {:ok, {a,b}}
      _ -> {:error, {:serialized_identifier, :unexpected_structure, identifier}}
    end
  end
end