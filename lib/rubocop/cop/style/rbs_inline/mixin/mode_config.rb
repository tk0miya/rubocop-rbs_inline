# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Resolves the `Mode` setting shared by every cop in the `Style/RbsInline`
        # department.
        #
        # @rbs module-self RuboCop::Cop::Base
        module ModeConfig
          # @rbs! type mode = :opt_in | :opt_out

          SUPPORTED_MODES = %i[opt_in opt_out].freeze #: Array[mode]

          # Hook RuboCop calls while mobilizing its cops, so an unsupported `Mode`
          # fails the run as a config error instead of an error on every file.
          def validate_config #: void
            configured_mode
          end

          private

          def configured_mode #: mode
            raw = cop_config["Mode"]
            # `raw.to_s.to_sym` handles YAML-native Integer / Boolean without
            # raising NoMethodError on the plain `to_sym`.
            mode = raw.to_s.to_sym
            return mode if SUPPORTED_MODES.include?(mode)

            raise ValidationError,
                  "`Style/RbsInline: Mode: #{raw.inspect}` is not supported. " \
                  "Expected one of: #{SUPPORTED_MODES.join(", ")}."
          end
        end
      end
    end
  end
end
