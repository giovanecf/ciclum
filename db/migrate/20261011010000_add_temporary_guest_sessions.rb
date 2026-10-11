class AddTemporaryGuestSessions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email, true
    change_column_null :users, :password_digest, true
    add_column :users, :guest_token_digest, :string
    add_column :users, :guest_expires_at, :datetime
    add_index :users, :guest_token_digest, unique: true
    add_index :users, :guest_expires_at
  end
end
