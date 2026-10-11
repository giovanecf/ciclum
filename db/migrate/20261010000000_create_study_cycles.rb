class CreateStudyCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :study_cycles do |t|
      t.string :name, null: false
      t.integer :weekly_reference_minutes, null: false, default: 1440
      t.boolean :active, null: false, default: false
      t.string :seed_key
      t.timestamps
    end
    add_index :study_cycles, :seed_key, unique: true
    add_index :study_cycles, :active, unique: true, where: "active = true", name: "only_one_active_cycle"
    create_table :cycle_subjects do |t|
      t.references :study_cycle, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :questions_count
      t.decimal :points_per_question, precision: 8, scale: 2
      t.integer :knowledge_level, null: false, default: 3
      t.integer :configured_minutes
      t.datetime :archived_at
      t.timestamps
    end
    add_index :cycle_subjects, [:study_cycle_id, :position]
    create_table :study_sessions do |t|
      t.references :study_cycle, null: false, foreign_key: true
      t.references :cycle_subject, null: false, foreign_key: true
      t.integer :minutes, null: false
      t.date :studied_on, null: false
      t.integer :sequence, null: false
      t.timestamps
    end
    add_index :study_sessions, [:study_cycle_id, :sequence], unique: true
  end
end
