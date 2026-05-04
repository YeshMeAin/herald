module Herald
  class ActionRegistry
    attr_reader :actions

    def initialize
      @actions = {}
    end

    def build!
      @actions = {}
      agentable_classes.each { |klass| register_class(klass) }
      freeze_registry!
    end

    def lookup(key)
      @actions[key]
    end

    def keys
      @actions.keys
    end

    def to_a
      @actions.values
    end

    private

    def agentable_classes
      Herald::Agentable.registered_classes.uniq.select do |klass|
        klass.respond_to?(:herald_allowed_actions) && klass.herald_allowed_actions.any?
      end
    end

    def register_class(klass)
      prefix = klass.name.underscore.tr("/", "_")

      klass.herald_allowed_actions.each do |action|
        key = "#{prefix}.#{action}"
        params = klass.herald_param_schema_for(action)
        description = klass.herald_action_descriptions[action]

        @actions[key] = ActionDescriptor.new(
          key: key,
          class_name: klass.name,
          action_name: action,
          params: params,
          description: description
        )
      end
    end

    def freeze_registry!
      @actions.freeze
    end
  end
end
