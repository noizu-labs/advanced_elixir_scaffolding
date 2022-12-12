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


  def update_handler(%{__struct__: table} = record, _previous, _context, _options) do
    table.write(record)
  end

  def update_handler!(%{__struct__: table} = record, _previous, _context, _options) do
    table.write!(record)
  end


  def delete_handler(%{__struct__: table} = record, _context, _options) do
    table.delete(record.identifier)
  end

  def delete_handler!(%{__struct__: table} = record, _context, _options) do
    table.delete!(record.identifier)
  end


  deftable AdvancedScaffolding.Test.Fixture.V3.RedisJsonCache.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisJsonCache.Entity
    @derive Noizu.ERP
  end


  deftable AdvancedScaffolding.Test.Fixture.V3.RocksDB.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.ConCache.Entity
    @derive Noizu.ERP
  end
  

  deftable AdvancedScaffolding.Test.Fixture.V3.ConCache.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.ConCache.Entity
    @derive Noizu.ERP
  end



  deftable AdvancedScaffolding.Test.Fixture.V3.RedisCache.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.RedisCache.Entity
    @derive Noizu.ERP
  end
  

  deftable AdvancedScaffolding.Test.Fixture.V3.Foo.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Entity
    @derive Noizu.ERP
  end


  deftable AdvancedScaffolding.Test.Fixture.V3.Foo.Type.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %__MODULE__{
                 identifier: any,
                 entity: any
               }
    def __erp__(), do: Noizu.AdvancedScaffolding.Test.Fixture.V3.Foo.Type.Entity
    @derive Noizu.ERP
  end
end
