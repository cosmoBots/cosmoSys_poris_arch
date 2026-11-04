module CosmosysPorisArch
  class Binding < ActiveRecord::Base
    self.table_name = 'cosmosys_poris_arch_bindings'
    belongs_to :system, class_name: 'Issue'
    belongs_to :component, class_name: 'Issue'
    has_many :parameter_links, class_name: 'CosmosysPorisArch::ParameterLink', dependent: :destroy
    has_many :command_policies, class_name: 'CosmosysPorisArch::CommandPolicy', dependent: :destroy
    validates :trigger, inclusion: {in: %w[command commit]}
    validates :component_id, uniqueness: {scope: :system_id}
    validate :consistent_endpoints

    def system_items
      system.self_and_descendants
    end

    def component_items
      component.self_and_descendants
    end

    def visible_to?(user)
      system.visible?(user) && component.visible?(user)
    end

    def editable_by?(user)
      user.admin? || [system.project, component.project].all? { |p| user.allowed_to?(:manage_poris_arch, p) && user.allowed_to?(:edit_issues, p) }
    end

    private

    def consistent_endpoints
      return unless system && component
      errors.add(:system, 'must be a PORIS system') unless system.cosmosys_item_kind_key == 'poris_sys'
      errors.add(:component, 'must be an architectural node with a CAD model') unless component.cosmosys_arch_node? && component.cosmosys_arch_model
      errors.add(:base, 'Both endpoints must share the same project root') unless system.project.root.id == component.project.root.id
    end
  end
end
