module Herald
  class Dispatcher
    def initialize(registry: Herald.registry)
      @registry = registry
    end

    def dispatch(action_key, params)
      descriptor = @registry.lookup(action_key)
      raise Error, "Unknown action: #{action_key}" unless descriptor

      klass = descriptor.class_name.constantize
      action = descriptor.action_name

      validate_params!(descriptor, params)

      if klass.respond_to?(:herald_ar_model?) && klass.herald_ar_model? && crud_action?(action)
        execute_crud(klass, action, params)
      else
        execute_method(klass, action, params)
      end
    end

    private

    def crud_action?(action)
      Herald::Agentable::CRUD_ACTIONS.include?(action)
    end

    def execute_crud(klass, action, params)
      case action
      when :index
        records = klass.where(params.compact)
        records.map { |r| r.attributes }.to_s
      when :show
        record = klass.find(params["id"])
        record.attributes.to_s
      when :create
        record = klass.create!(params)
        "Created #{klass.name} ##{record.id}"
      when :update
        record = klass.find(params.delete("id"))
        record.update!(params)
        "Updated #{klass.name} ##{record.id}"
      when :destroy
        record = klass.find(params["id"])
        record.destroy!
        "Destroyed #{klass.name} ##{params["id"]}"
      end
    end

    def execute_method(klass, action, params)
      instance = klass.new
      result = if params.any?
                 instance.public_send(action, **params.symbolize_keys)
               else
                 instance.public_send(action)
               end
      result.to_s
    end

    def validate_params!(descriptor, params)
      required = descriptor.params.select { |p| p[:required] }.map { |p| p[:name] }
      missing = required - params.keys.map(&:to_s)
      raise Error, "Missing required params: #{missing.join(", ")}" if missing.any?
    end
  end
end
