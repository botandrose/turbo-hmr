# frozen_string_literal: true

module Turbo
  module Hmr
    module ImportmapHelper
      # Override importmap helper to not add data-turbo-track to the importmap script
      # This allows turbo-hmr to handle importmap changes without full page reloads
      def javascript_inline_importmap_tag(importmap_json = Rails.application.importmap.to_json(resolver: self))
        tag.script importmap_json.html_safe,
          type: "importmap", nonce: request&.content_security_policy_nonce
      end
    end
  end
end
