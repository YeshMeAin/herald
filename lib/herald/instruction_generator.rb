module Herald
  class InstructionGenerator
    def initialize(registry: Herald.registry)
      @registry = registry
    end

    def generate
      sections = []
      sections << header
      sections << actions_by_class
      sections << footer
      sections.join("\n\n")
    end

    def write!
      path = Herald.configuration.instructions_path
      File.write(path, generate)
      path
    end

    private

    def header
      <<~MD.strip
        # Herald Agent Instructions

        You are an agent that helps manage a Rails application.
        You can only perform the actions listed below. Do not attempt any action not listed here.

        Respond with a JSON object containing:
        - "action": the action key (e.g. "inventory_item.show")
        - "params": a hash of parameters

        If the user's request doesn't map to any available action, respond with:
        - "action": "none"
        - "message": a helpful explanation of what you can do
      MD
    end

    def actions_by_class
      grouped = @registry.to_a.group_by(&:class_name)
      grouped.map { |class_name, descriptors| class_section(class_name, descriptors) }.join("\n\n")
    end

    def class_section(class_name, descriptors)
      klass = class_name.constantize
      desc = klass.respond_to?(:herald_class_description) ? klass.herald_class_description : nil

      lines = []
      lines << "## #{class_name}"
      lines << desc if desc
      lines << ""

      descriptors.each do |descriptor|
        lines << action_section(descriptor)
      end

      lines.join("\n")
    end

    def action_section(descriptor)
      lines = []
      lines << "### `#{descriptor.key}`"
      lines << descriptor.description if descriptor.description
      lines << ""

      if descriptor.params.any?
        lines << "Parameters:"
        descriptor.params.each do |param|
          req = param[:required] ? "required" : "optional"
          lines << "- `#{param[:name]}` (#{param[:type]}, #{req})"
        end
      else
        lines << "No parameters."
      end

      lines << ""
      lines.join("\n")
    end

    def footer
      <<~MD.strip
        ---
        Only use the actions listed above. If unsure, ask for clarification.
      MD
    end
  end
end
