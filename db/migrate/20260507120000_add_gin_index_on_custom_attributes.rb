class AddGinIndexOnCustomAttributes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Speeds up filtering by JSONB custom_attributes (e.g. "Posicion Propuesta
    # Contiene X"). Without these indexes, ILIKE on `custom_attributes ->> 'key'`
    # forces a full table scan and the conversations filter hangs.
    add_index :contacts, :custom_attributes, using: :gin, algorithm: :concurrently,
                                              if_not_exists: true,
                                              name: 'index_contacts_on_custom_attributes_gin'
    add_index :conversations, :custom_attributes, using: :gin, algorithm: :concurrently,
                                                   if_not_exists: true,
                                                   name: 'index_conversations_on_custom_attributes_gin'
  end

  def down
    remove_index :contacts, name: 'index_contacts_on_custom_attributes_gin', if_exists: true, algorithm: :concurrently
    remove_index :conversations, name: 'index_conversations_on_custom_attributes_gin', if_exists: true, algorithm: :concurrently
  end
end
