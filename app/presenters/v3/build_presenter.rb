require 'presenters/v3/base_presenter'

module VCAP::CloudController
  module Presenters
    module V3
      class BuildPresenter < BasePresenter
        def to_hash
          {
            guid: build.guid,
            created_at: build.created_at,
            updated_at: build.updated_at,
            state: build.state,
            error: error,
            lifecycle: {
              type: build.lifecycle_type,
              data: build.lifecycle_data.to_hash
            },
            memory_in_mb: build.memory_in_mb,
            disk_in_mb: build.disk_in_mb,
            package: { guid: build.package_guid },
            droplet: droplet,
            links: build_links,
          }
        end

        private

        def build
          @resource
        end

        def droplet
          if build.droplet&.in_final_state?
            return { guid: build.droplet.guid, href: url_builder.build_url(path: "/v3/droplets/#{build.droplet.guid}") }
          end
          nil
        end

        def error
          e = [build.error_id, build.error_description].compact.join(' - ')
          e.blank? ? nil : e
        end

        def build_links
          {
            self: { href: url_builder.build_url(path: "/v3/builds/#{build.guid}") },
            app: { href: url_builder.build_url(path: "/v3/apps/#{build.app.guid}") },
          }
        end

        def url_builder
          @url_builder ||= VCAP::CloudController::Presenters::ApiUrlBuilder.new
        end
      end
    end
  end
end
