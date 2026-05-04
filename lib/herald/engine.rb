module Herald
  class Engine < ::Rails::Engine
    isolate_namespace Herald

    initializer "herald.build_registry" do
      ActiveSupport.on_load(:active_record) do
        Rails.application.config.after_initialize do
          Herald.registry.build!
        end
      end
    end
  end
end
