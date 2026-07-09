# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Filters files a cop reports offenses on, based on `Mode` configuration.
        #
        # When `Mode` is `opt_in`, offenses are only reported for files that contain
        # a `# rbs_inline: enabled` magic comment.
        # When `Mode` is `opt_out`, or when it is not set (legacy default), all files
        # are checked as usual.
        #
        # This module is designed to be `prepend`ed to a cop so that it can short-circuit
        # the cop's heavy work (annotation parsing via `parse_comments`) and suppress any
        # residual offense reporting for files that should be skipped.
        #
        # @rbs module-self RuboCop::Cop::Base
        module FileFilter
          MAGIC_COMMENT_ENABLED = /^# rbs_inline: enabled[ \t]*$/ #: Regexp

          # @rbs @rbs_inline_skip_file: bool

          def on_new_investigation #: void
            @rbs_inline_skip_file = skip_by_mode?
            super
          end

          # @rbs *args: untyped
          # @rbs **kwargs: untyped
          def add_offense(*args, **kwargs, &) #: void
            return if @rbs_inline_skip_file

            super
          end

          private

          def skip_by_mode? #: bool
            case cop_config["Mode"]&.to_sym
            when :opt_in then !rbs_inline_enabled?
            else false
            end
          end

          # Look for the `# rbs_inline: enabled` magic comment directly in the raw source.
          # This avoids materializing / iterating `processed_source.comments`; the pragma
          # is a line-anchored literal so a single regex scan is sufficient.
          def rbs_inline_enabled? #: bool
            processed_source.raw_source.match?(MAGIC_COMMENT_ENABLED)
          end
        end
      end
    end
  end
end
