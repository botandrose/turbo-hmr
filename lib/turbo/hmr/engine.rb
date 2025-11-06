# frozen_string_literal: true

module Turbo
  module Hmr
    class Engine < ::Rails::Engine
      isolate_namespace Turbo::Hmr

      initializer "turbo_hmr.assets" do |app|
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.precompile += %w[turbo-hmr.js]
      end

      initializer "turbo_hmr.importmap_helper" do
        ActiveSupport.on_load(:action_controller) do
          helper Turbo::Hmr::ImportmapHelper
        end
      end
    end
  end
end
