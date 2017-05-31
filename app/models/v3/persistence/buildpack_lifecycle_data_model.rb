require 'cloud_controller/diego/lifecycles/lifecycles'
require 'utils/uri_utils'

module VCAP::CloudController
  class BuildpackLifecycleDataModel < Sequel::Model(:buildpack_lifecycle_data)
    LIFECYCLE_TYPE = Lifecycles::BUILDPACK

    encrypt :buildpack_url, salt: :encrypted_buildpack_url_salt, column: :encrypted_buildpack_url

    many_to_one :droplet,
      class:                   '::VCAP::CloudController::DropletModel',
      key:                     :droplet_guid,
      primary_key:             :guid,
      without_guid_generation: true

    many_to_one :build,
      class:                   '::VCAP::CloudController::BuildModel',
      key:                     :build_guid,
      primary_key:             :guid,
      without_guid_generation: true

    many_to_one :app,
      class:                   '::VCAP::CloudController::AppModel',
      key:                     :app_guid,
      primary_key:             :guid,
      without_guid_generation: true

    def buildpack_identifier=(buildpack_identifier)
      self.buildpack_url        = nil
      self.admin_buildpack_name = nil

      if UriUtils.is_uri?(buildpack_identifier)
        self.buildpack_url = buildpack_identifier
      else
        self.admin_buildpack_name = buildpack_identifier
      end
    end
    # alias_method :buildpack=, :buildpack_identifier=

    def buildpack_identifier
      return self.admin_buildpack_name if self.admin_buildpack_name.present?
      self.buildpack_url
    end
    # alias_method :buildpack, :buildpack_identifier

    def buildpack_model
      return AutoDetectionBuildpack.new if buildpack_identifier.nil?

      known_buildpack = Buildpack.find(name: buildpack_identifier)
      return known_buildpack if known_buildpack

      CustomBuildpack.new(buildpack_identifier)
    end

    def to_hash
      { buildpacks: buildpack_identifier ? [CloudController::UrlSecretObfuscator.obfuscate(buildpack_identifier)] : [], stack: stack }
    end

    def validate
      if app && (build || droplet)
        errors.add(:lifecycle_data, 'Must be associated with an app OR a build+droplet, but not both')
      end
    end
  end
end
