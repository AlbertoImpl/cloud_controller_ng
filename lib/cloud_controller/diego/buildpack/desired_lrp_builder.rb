module VCAP::CloudController
  module Diego
    module Buildpack
      class DesiredLrpBuilder
        include ::Diego::ActionBuilder

        def initialize(config, opts)
          @config = config
          @stack = opts[:stack]
          @droplet_uri = opts[:droplet_uri]
          @process_guid = opts[:process_guid]
          @droplet_hash = opts[:droplet_hash]
          @ports = opts[:ports]
          @checksum_algorithm = opts[:checksum_algorithm]
          @checksum_value = opts[:checksum_value]
        end

        def cached_dependencies
          lifecycle_bundle_key = "buildpack/#{@stack}".to_sym
          [
            ::Diego::Bbs::Models::CachedDependency.new(
              from: LifecycleBundleUriGenerator.uri(@config[:diego][:lifecycle_bundles][lifecycle_bundle_key]),
              to: '/tmp/lifecycle',
              cache_key: "buildpack-#{@stack}-lifecycle"
            )
          ]
        end

        def root_fs
          "preloaded:#{@stack}"
        end

        def setup
          serial([
            ::Diego::Bbs::Models::DownloadAction.new(
              from: @droplet_uri,
              to: '.',
              cache_key: "droplets-#{@process_guid}",
              user: 'vcap',
              checksum_algorithm: @checksum_algorithm,
              checksum_value: @checksum_value,
            )
          ])
        end

        def global_environment_variables
          [::Diego::Bbs::Models::EnvironmentVariable.new(name: 'LANG', value: DEFAULT_LANG)]
        end

        def ports
          @ports || [DEFAULT_APP_PORT]
        end

        def privileged?
          @config[:diego][:use_privileged_containers_for_running]
        end

        def action_user
          'vcap'
        end
      end
    end
  end
end
