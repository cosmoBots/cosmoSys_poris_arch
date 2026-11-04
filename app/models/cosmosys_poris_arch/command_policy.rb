module CosmosysPorisArch
  class CommandPolicy < ActiveRecord::Base
    self.table_name = 'cosmosys_poris_arch_command_policies'
    belongs_to :binding, class_name: 'CosmosysPorisArch::Binding'
    belongs_to :command, class_name: 'Issue'
    validates :command_id, uniqueness: {scope: :binding_id}
    validates :actuation, inclusion: {in: [true, false]}
    validate do
      if binding && command && !(command.cosmosys_item_kind_key == 'poris_cmd' && binding.system_items.exists?(id: command.id))
        errors.add(:command, 'must belong to the bound PORIS system')
      end
    end
  end
end
