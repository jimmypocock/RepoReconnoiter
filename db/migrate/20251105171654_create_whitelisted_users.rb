class CreateWhitelistedUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :whitelisted_users do |t|
      t.integer :github_id
      t.string :github_username
      t.string :email
      t.string :added_by
      t.text :notes

      t.timestamps
    end
    add_index :whitelisted_users, :github_id, unique: true
  end
end
