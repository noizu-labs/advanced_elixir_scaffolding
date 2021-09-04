#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2021 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.AdvancedScaffolding.Internal.DomainObject.Entity do
  @moduledoc """
    Provides scaffolding for DomainObject.Entity
  """

  #--------------------------------------------
  # __noizu_entity__/3
  #--------------------------------------------
  @doc """
  Initialize a DomainObject.Entity. Caller passes in identifier and field definitions which are in turn used to generate the domain object entity's configuration options and defstruct statement.
  """
  def __noizu_entity__(caller, options, block) do


    extension_provider = options[:extension_implementation] || nil
    extension_block_a = extension_provider && quote do: (use unquote(extension_provider), unquote(options))
    extension_block_b = extension_provider && extension_provider.pre_defstruct(options)
    extension_block_c = extension_provider && extension_provider.post_defstruct(options)
    extension_block_d = extension_provider && quote do
                                                @before_compile unquote(extension_provider)
                                                @after_compile  unquote(extension_provider)
                                              end

    core_configuration = Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour.__configure__(options)
    core_implementation = Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour.__implement__(options)

    persistence_configuration = Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour.__configure__(options)
    persistence_implementation = Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour.__implement__(options)

    index_configuration = Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour.__configure__(options)
    index_implementation = Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour.__implement__(options)

    json_configuration = Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour.__configure__(options)
    json_implementation = Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour.__implement__(options)

    inspect_configuration = Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Behaviour.__configure__(options)
    inspect_implementation = Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Behaviour.__implement__(options)


    process_config = quote do
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       require Noizu.DomainObject
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity
                       require Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros
                       require Noizu.AdvancedScaffolding.Internal.Helpers
                       import Noizu.ElixirCore.Guards
                       @options unquote(options)
                       #---------------------
                       # Insure Single Call
                       #---------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       Noizu.AdvancedScaffolding.Internal.Helpers.insure_single_use(:__nzdo__entity_defined, unquote(caller))

                       #--------------------
                       # Extract configuration details from provided options/set attributes/base attributes/config methods.
                       #--------------------
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(core_configuration)
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(persistence_configuration)
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(index_configuration)
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(json_configuration)
                       @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                       unquote(inspect_configuration)


                       #----------------------
                       # User block section (define, fields, constraints, json_mapping rules, etc.)
                       #----------------------
                       # Prep attributes for loading individual fields.
                       @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__register__field_attributes__macro__(unquote(options))

                       try do
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         # we rely on the same providers as used in the Entity type for providing json encoding, restrictions, etc.
                         import Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros, only: [
                           identifier: 0, identifier: 1, identifier: 2,
                           ecto_identifier: 0, ecto_identifier: 1, ecto_identifier: 2,
                           public_field: 1, public_field: 2, public_field: 3, public_fields: 1, public_fields: 2,
                           restricted_field: 1, restricted_field: 2, restricted_field: 3, restricted_fields: 1, restricted_fields: 2,
                           private_field: 1, private_field: 2, private_field: 3, private_fields: 1, private_fields: 2,
                           internal_field: 1, internal_field: 2, internal_field: 3, internal_fields: 1, internal_fields: 2,
                           transient_field: 1, transient_field: 2, transient_field: 3, transient_fields: 1, transient_fields: 2,
                         ]
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         unquote(extension_block_a)
                         @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
                         unquote(block)
                       after
                         :ok
                       end
                       unquote(extension_block_b)
                       Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.Field.Macros.__post_struct_definition_macro__(unquote(options))
                     end

    generate = quote unquote: false do
                 @derive @__nzdo__derive
                 defstruct @__nzdo__fields
               end

    quote do
      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      unquote(process_config)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(generate)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(core_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(persistence_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(index_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(json_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(inspect_implementation)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      unquote(extension_block_c)

      @before_compile Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour
      @before_compile Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour
      @before_compile Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour
      @before_compile Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour
      @before_compile Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Behaviour

      @after_compile Noizu.AdvancedScaffolding.Internal.Core.Entity.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Persistence.Entity.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.EntityIndex.Entity.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Json.Entity.Behaviour
      @after_compile Noizu.AdvancedScaffolding.Internal.Inspect.Entity.Behaviour

      @file unquote(__ENV__.file) <> "(#{unquote(__ENV__.line)})"
      unquote(extension_block_d)
      @file __ENV__.file
    end
  end

end
