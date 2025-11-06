# frozen_string_literal: true

module Turbo
  module Hmr
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc "Installs turbo-hmr"

        def update_importmap
          append_to_file "config/importmap.rb", %(pin "turbo-hmr", to: "turbo-hmr.js"\n)
        end

        def update_application_js
          application_js_path = "app/javascript/application.js"

          # Read the existing content to determine where to add the code
          if File.exist?(application_js_path)
            content = File.read(application_js_path)

            # Add the import at the top if not already present
            unless content.include?('from "turbo-hmr"')
              prepend_to_file application_js_path, "import { start as startTurboHmr } from \"turbo-hmr\"\n"
            end

            # Add the start call after Stimulus is initialized
            unless content.include?("startTurboHmr")
              # Try to add after Application.start() or window.Stimulus assignment
              if content.match(/(?:const|let|var)\s+(\w+)\s*=.*Application\.start\(\)/)
                app_var = Regexp.last_match(1)
                inject_into_file application_js_path, "\nstartTurboHmr(#{app_var})\n",
                  after: /#{app_var}\s*=.*Application\.start\(\)/
              elsif content.match(/window\.Stimulus\s*=.*Application\.start\(\)/)
                inject_into_file application_js_path, "\nstartTurboHmr(window.Stimulus)\n",
                  after: /window\.Stimulus\s*=.*Application\.start\(\)/
              else
                append_to_file application_js_path, "\n// Start turbo-hmr (adjust the application variable name as needed)\n// startTurboHmr(application)\n"
              end
            end
          else
            create_file application_js_path, <<~JS
              import { start as startTurboHmr } from "turbo-hmr"
              import { Application } from "@hotwired/stimulus"

              const application = Application.start()
              startTurboHmr(application)
            JS
          end
        end
      end
    end
  end
end
