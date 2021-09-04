defmodule Noizu.DomainObject.TypeHandler do
  @moduledoc """
  Field Type Handler to assist mapping entity fields into and out of different persistence layer formats, and to deal with persistence for fields which are
  nested fields in our DomainObject.Entity  but are written to their own tables in RDMS or even Mnesia format, or which generate additional indexing artifacts during creation/updates.

  For example an Entity.time_stamp field should expand out to  [{created_on, DateTime.to_unix(timestamp.created)}, ...] when writing to Mnesia for example to support date time unix epoch index columns.
  ```
  %Mnesia.Table{
    identifier: identifier,
    created_on: unix_time_stamp,
    entity:  %MyEntity{
      time_stamp: %{created_on: DateTime.t}
    }
  }
  ```
  """


  defmodule Behaviour do
  @callback compare(any, any) :: :eq | :neq | :lt | :gt

  @callback sync(any, any, any) :: any
  @callback sync(any, any, any, any) :: any
  @callback sync!(any, any, any) :: any
  @callback sync!(any, any, any, any) :: any

  @callback __strip_inspect__(any, any, any) :: any

  @callback pre_create_callback(any, any, any, any) :: any
  @callback pre_create_callback!(any, any, any, any) :: any

  @callback pre_update_callback(any, any, any, any) :: any
  @callback pre_update_callback!(any, any, any, any) :: any

  @callback post_delete_callback(any, any, any, any) :: any
  @callback post_delete_callback!(any, any, any, any) :: any

  @callback dump(any, any, any, any, any, any, any) :: any
  @callback cast(any, any, any, any, any, any) :: any

  @callback from_json(format :: any, field :: atom,  json :: any, context :: any, options :: any) :: map() | nil

  end

  #--------------------------------------------
  #
  #--------------------------------------------
  def __noizu_type_handler__(_caller, _options) do
    quote do
      import Noizu.ElixirCore.Guards
      @behaviour Noizu.DomainObject.TypeHandler.Behaviour

      @doc """
        Determine if two instances of this type match. Possibly ignoring erroneous fields such as time stamps/transient fields, etc.
      """
      def compare(nil, nil), do: :eq
      def compare(nil, _), do: :neq
      def compare(_, nil), do: :neq
      def compare(a, b), do: a ==b && :eq || :neq

      @doc """
        Merge existing and updated instance of type.
      """
      def sync(existing, update, context, options \\ nil)
      def sync(existing, nil, _context, _options), do: existing
      def sync(nil, update, _context, _options), do: update
      def sync(existing, _update, _context, _options), do: existing

      @doc """
        Merge existing and updated instance of type.
      """
      def sync!(existing, update, context, options \\ nil), do: sync(existing, update, context, options)

      @doc """
        Format instance of type for Inspect output. - strip fields, simplify object, etc.
      """
      def __strip_inspect__(field, value, _opts), do: {field, value}

      @doc """
      Post get callback, to allow, for example, injecting data into a transient field or running additional queries needed to populate a domain object entity field.
      """
      def post_get_callback(_field, entity, _context, _options), do: entity
      @doc """
      (Dirty) Post get callback, to allow, for example, injecting data into a transient field or running additional queries needed to populate a domain object entity field.
      """
      def post_get_callback!(field, entity, context, options), do: post_get_callback(field, entity, context, options)

      @doc """
      pre create callback.
      Users may have provided a simplified representation of this type, that we need to expand into the correct type and or possibly expand and write to the database before
      proceeding to create the entity that contains this field.
      """
      def pre_create_callback(_field, entity, _context, _options), do: entity
      @doc """
      (Dirty) pre create callback.
      Users may have provided a simplified representation of this type, that we need to expand into the correct type and or possibly expand and write to the database before
      proceeding to create the entity that contains this field.
      """
      def pre_create_callback!(field, entity, context, options), do: pre_create_callback(field, entity, context, options)

      @doc """
      post create callback.
      Post entity creation callback . If, for example, we wish to save this field to its own tables after creating the records for the entity containing this field
      """
      def post_create_callback(_field, entity, _context, _options), do: entity

      @doc """
      (Dirty) post create callback.
      Post entity creation callback . If, for example, we wish to save this field to its own tables after creating the records for the entity containing this field
      """
      def post_create_callback!(field, entity, context, options), do: post_create_callback(field, entity, context, options)

      @doc """
      pre update callback for entity fields of this type.
      """
      def pre_update_callback(_field, entity, _context, _options), do: entity

      @doc """
      (Dirty) pre update callback for entity fields of this type.
      """
      def pre_update_callback!(field, entity, context, options), do: pre_update_callback(field, entity, context, options)

      @doc """
      post update callback for entity fields of this type.
      """
      def post_update_callback(_field, entity, _context, _options), do: entity

      @doc """
      (Dirty) post update callback for entity fields of this type.
      """
      def post_update_callback!(field, entity, context, options), do: post_update_callback(field, entity, context, options)

      @doc """
      pre delete callback for entity fields of this type.
      """
      def pre_delete_callback(_field, entity, _context, _options), do: entity

      @doc """
      (Dirty) pre delete callback for entity fields of this type.
      """
      def pre_delete_callback!(field, entity, context, options), do: pre_delete_callback(field, entity, context, options)

      @doc """
      post delete callback for entity fields of this type.
      """
      def post_delete_callback(_field, entity, _context, _options), do: entity

      @doc """
      (Dirty) post delete callback for entity fields of this type.
      """
      def post_delete_callback!(field, entity, context, options), do: post_delete_callback(field, entity, context, options)

      @doc """
      Cast database record fields back into entity.field of this type.
      For example to reconstruct a TimeStamp entity by grabbing the RDMS table's created_on, modified_on, deleted_on fields.
      """
      def cast(field, record, _type, _layer, _context, _options), do: [{field, record && get_in(record, [Access.key(field)])}]


      @doc """
      Cast database record fields to database format.
      """
      def dump(field, _segment, value, _type, _layer, _context, _options), do: {field, value}

      def from_json(_format, _field, _json, _context, _options), do: nil

      defoverridable [
        compare: 2,
        sync: 3,
        sync: 4,
        sync!: 3,
        sync!: 4,
        __strip_inspect__: 3,
        post_get_callback: 4,
        post_get_callback!: 4,
        pre_create_callback: 4,
        pre_create_callback!: 4,
        post_create_callback: 4,
        post_create_callback!: 4,
        pre_update_callback: 4,
        pre_update_callback!: 4,
        post_update_callback: 4,
        post_update_callback!: 4,
        pre_delete_callback: 4,
        pre_delete_callback!: 4,
        post_delete_callback: 4,
        post_delete_callback!: 4,
        cast: 6,
        dump: 7,
        from_json: 5
      ]
    end
  end

end
