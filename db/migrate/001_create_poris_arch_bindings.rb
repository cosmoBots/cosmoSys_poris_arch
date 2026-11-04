class CreatePorisArchBindings < ActiveRecord::Migration[6.1]
  def change
    issue_id_limit = connection.columns(:issues).find { |column| column.name == 'id' }.limit
    create_table :cosmosys_poris_arch_bindings do |t|
      t.integer :system_id, limit: issue_id_limit, null: false
      t.integer :component_id, limit: issue_id_limit, null: false
      t.string :trigger, null: false, default: 'command'
      t.timestamps
    end
    add_index :cosmosys_poris_arch_bindings, [:system_id, :component_id], unique: true, name: 'idx_cpa_binding_pair'
    add_foreign_key :cosmosys_poris_arch_bindings, :issues, column: :system_id, on_delete: :cascade
    add_foreign_key :cosmosys_poris_arch_bindings, :issues, column: :component_id, on_delete: :cascade
    create_table :cosmosys_poris_arch_parameter_links do |t|
      t.references :binding, null: false, index: {name: 'idx_cpa_link_binding'}, foreign_key: {to_table: :cosmosys_poris_arch_bindings, on_delete: :cascade}
      t.integer :parameter_id, limit: issue_id_limit, null: false
      t.integer :dof_id, limit: issue_id_limit, null: false
      t.float :multiplier, null: false, default: 1.0
      t.float :offset, null: false, default: 0.0
      t.text :discrete_values, null: false
      t.timestamps
    end
    add_index :cosmosys_poris_arch_parameter_links, [:binding_id, :parameter_id, :dof_id], unique: true, name: 'idx_cpa_link_target'
    add_foreign_key :cosmosys_poris_arch_parameter_links, :issues, column: :parameter_id, on_delete: :cascade
    add_foreign_key :cosmosys_poris_arch_parameter_links, :issues, column: :dof_id, on_delete: :cascade
    create_table :cosmosys_poris_arch_command_policies do |t|
      t.references :binding, null: false, index: {name: 'idx_cpa_policy_binding'}, foreign_key: {to_table: :cosmosys_poris_arch_bindings, on_delete: :cascade}
      t.integer :command_id, limit: issue_id_limit, null: false
      t.boolean :actuation, null: false, default: true
      t.timestamps
    end
    add_index :cosmosys_poris_arch_command_policies, [:binding_id, :command_id], unique: true, name: 'idx_cpa_policy_command'
    add_foreign_key :cosmosys_poris_arch_command_policies, :issues, column: :command_id, on_delete: :cascade
  end
end
