class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.string :name, null: false
      t.string :key_digest, null: false
      t.datetime :last_used_at
      t.integer :request_count, default: 0, null: false
      t.datetime :revoked_at
      t.references :user, null: true, foreign_key: true  # Nullable for system keys

      t.timestamps
    end

    # Indexes for performance
    add_index :api_keys, :key_digest, unique: true
    add_index :api_keys, :revoked_at
    add_index :api_keys, [ :user_id, :revoked_at ]
  end
end
