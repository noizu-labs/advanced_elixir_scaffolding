#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase NoizuSchema.Database do

  def database(), do: NoizuSchema.Database


  def create_handler(%{__struct__: table} = record, _context, _options) do
    table.write(record)
  end

  def create_handler!(%{__struct__: table} = record, _context, _options) do
    table.write!(record)
  end

  def update_handler(%{__struct__: table} = record, _context, _options) do
    table.write(record)
  end

  def update_handler!(%{__struct__: table} = record, _context, _options) do
    table.write!(record)
  end

  def delete_handler(%{__struct__: table} = record, _context, _options) do
    table.delete(record.identifier)
  end

  def delete_handler!(%{__struct__: table} = record, _context, _options) do
    table.delete!(record.identifier)
  end


  deftable Scaffolding.Test.Fixture.V3.Foo.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.Scaffolding.Test.Fixture.V3.Foo.Entity
    @derive Noizu.ERP
  end


  deftable Scaffolding.Test.Fixture.V3.Foo.Type.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.Scaffolding.Test.Fixture.V3.Foo.Type.Entity
    @derive Noizu.ERP
  end
end
