#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedScaffolding.Types do
  @type entity_identifier :: any
  @type sref :: String.t
  @type ref :: {:ref, atom, any}
  @type entity_or_ref :: ref | map() | sref | entity_identifier
  @type options :: list | map() | nil

  @type identifier_type :: any

  @type nmid_setting :: :all | :generator | :sequencer |:bare | :index

  @type noizu_info_setting__erp :: :base | :entity | :struct | :repo | :sref | :poly
  @type noizu_info_setting__json :: :json_configuration
  @type noizu_info_setting__field :: :fields | :field_attributes | :field_permissions |:field_types | :associated_types
  @type noizu_info_setting__permissions :: :restrict_provider
  @type noizu_info_setting__persistence :: :persistence
  @type noizu_info_setting__indexing :: :indexing

  @type noizu_info_setting :: :all | :type | :identifier_type | :meta | :enum | :noizu_info_setting__erp | :noizu_info_setting__json | :noizu_info_setting__field | :noizu_info_setting__permissions | :noizu_info_setting__persistence | :noizu_info_setting__indexing


end
