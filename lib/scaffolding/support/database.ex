#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.AdvancedScaffolding.Database do

  #-----------------------------------------------------------------------------
  # Ref Resolution Lookup Table
  #-----------------------------------------------------------------------------
  deftable UniversalReverseLookup.Table, [:identifier, :ref], type: :set, index: [] do
    @type t :: %UniversalReverseLookup.Table{
                 identifier: Types.integer,
                 ref: atom,
               }
  end

  deftable UniversalLookup.Table, [:identifier, :universal_identifier], type: :set, index: [] do
    @type t :: %UniversalLookup.Table{
                 identifier: tuple,
                 universal_identifier: atom,
               }
  end

  deftable EctoIdentifierLookup.Table, [:identifier, :ecto_identifier], type: :set, index: [] do
    @type t :: %EctoIdentifierLookup.Table{
                 identifier: tuple,
                 ecto_identifier: atom,
               }
  end

  deftable NmidV3Generator.Table, [:key, :incr], type: :ordered_set, index: [] do
    @type t :: %NmidV3Generator.Table{key: integer, incr: integer}
  end

end
