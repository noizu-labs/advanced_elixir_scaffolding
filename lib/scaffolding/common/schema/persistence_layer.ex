defmodule Noizu.AdvancedScaffolding.Schema.PersistenceLayer do
  @vsn 1.0
  @type t :: %__MODULE__{
               schema: atom,
               type: atom,
               table: atom,
               id_map: any,
               dirty?: boolean,
               fragmented?: boolean,
               require_transaction?: boolean,
               tx_block: atom,
               load_fallback?: boolean,

               cascade_create?: boolean,
               cascade_delete?: boolean,
               cascade_update?: boolean,
               cascade_block?: boolean,

               schema_fields: map(),
               options: list,
               vsn: float
             }

  defstruct [
    schema: nil,
    type: nil,
    table: nil,
    id_map: :same,
    dirty?: false,
    fragmented?: false,
    tx_block: :none,
    require_transaction?: false,

    load_fallback?: false,

    cascade_create?: false,
    cascade_delete?: false,
    cascade_update?: false,
    cascade_block?: false,

    schema_fields: %{},
    options: [],
    vsn: @vsn
  ]
end
