class RemoveExplicitValueMaps < ActiveRecord::Migration[6.1]
  def up
    remove_column :cosmosys_poris_arch_parameter_links, :discrete_values if
      column_exists?(:cosmosys_poris_arch_parameter_links, :discrete_values)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Restore the database backup to recover removed value maps'
  end
end
