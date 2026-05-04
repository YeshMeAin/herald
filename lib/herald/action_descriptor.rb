module Herald
  class ActionDescriptor
    attr_reader :key, :class_name, :action_name, :params, :description

    def initialize(key:, class_name:, action_name:, params:, description: nil)
      @key = key
      @class_name = class_name
      @action_name = action_name
      @params = params
      @description = description
    end

    def to_h
      {
        key: key,
        class_name: class_name,
        action_name: action_name,
        params: params,
        description: description
      }
    end
  end
end
