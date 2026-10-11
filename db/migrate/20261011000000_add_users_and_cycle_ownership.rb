class AddUsersAndCycleOwnership < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    add_reference :study_cycles, :user, foreign_key: true
    remove_index :study_cycles, name: "only_one_active_cycle"
    remove_index :study_cycles, :seed_key
    add_index :study_cycles, [:user_id, :seed_key], unique: true, where: "seed_key IS NOT NULL"
    add_index :study_cycles, :user_id, unique: true, where: "active = true", name: "only_one_active_cycle_per_user"
  end
end
