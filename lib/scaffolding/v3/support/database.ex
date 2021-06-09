#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.Scaffolding.V3.Database do

  #-----------------------------------------------------------------------------
  # Ref Resolution Lookup Table
  #-----------------------------------------------------------------------------
  deftable UniversalReverseLookupTable, [:identifier, :ref], type: :set, index: [] do
    @type t :: %UniversalReverseLookupTable{
                 identifier: Types.integer,
                 ref: atom,
               }
  end

  deftable UniversalLookupTable, [:identifier, :universal_identifier], type: :set, index: [] do
    @type t :: %UniversalLookupTable{
                 identifier: tuple,
                 universal_identifier: atom,
               }
  end

  deftable MySQLIdentifierLookupTable, [:identifier, :mysql_identifier], type: :set, index: [] do
    @type t :: %MySQLIdentifierLookupTable{
                 identifier: tuple,
                 mysql_identifier: atom,
               }
  end

  deftable NmidGenerator, [:key, :incr], type: :ordered_set, index: [] do
    @type t :: %NmidGenerator{key: integer, incr: integer}
  end

end
