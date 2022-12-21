#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2022 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.DomainObject.UniversalLookupBehaviour do
  @callback lookup(any) :: any
  @callback reverse_lookup(any) :: any
end