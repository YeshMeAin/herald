module Herald
  module Agentable
    extend ActiveSupport::Concern

    CRUD_ACTIONS = %i[index show create update destroy].freeze

    mattr_accessor :registered_classes, default: []

    included do
      Herald::Agentable.registered_classes << self

      class_attribute :herald_allowed_actions, default: []
      class_attribute :herald_class_description, default: nil
      class_attribute :herald_action_descriptions, default: {}
    end

    class_methods do
      def agent_actions(only:)
        self.herald_allowed_actions = Array(only).map(&:to_sym)
      end

      def agent_description(text)
        self.herald_class_description = text
      end

      def agent_action_description(action, text)
        self.herald_action_descriptions = herald_action_descriptions.merge(action.to_sym => text)
      end

      def herald_ar_model?
        respond_to?(:column_names) && respond_to?(:inheritance_column)
      end

      def herald_param_schema_for(action)
        if herald_ar_model?
          crud_params_for(action)
        else
          method_params_for(action)
        end
      end

      private

      def crud_params_for(action)
        case action
        when :index
          filterable_columns.map { |col| { name: col.name, type: col.type, required: false } }
        when :show, :destroy
          [{ name: "id", type: :integer, required: true }]
        when :create
          writable_columns.map { |col| { name: col.name, type: col.type, required: !col.null && !col.default } }
        when :update
          [{ name: "id", type: :integer, required: true }] +
            writable_columns.map { |col| { name: col.name, type: col.type, required: false } }
        else
          method_params_for(action)
        end
      end

      def method_params_for(action)
        return [] unless method_defined?(action) || private_method_defined?(action)

        instance_method(action).parameters.map do |kind, name|
          { name: name.to_s, type: :string, required: %i[req keyreq].include?(kind) }
        end
      end

      def writable_columns
        skip = %w[id created_at updated_at]
        columns.reject { |col| skip.include?(col.name) }
      end

      def filterable_columns
        columns
      end
    end
  end
end
