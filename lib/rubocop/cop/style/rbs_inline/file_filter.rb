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
        # This module is designed to be `prepend`ed to a cop so that it can suppress
        # offense reporting no matter which callback (`on_new_investigation`, `on_send`,
        # etc.) the cop uses to detect issues.
        #
        # @rbs module-self RuboCop::Cop::Base
        module FileFilter
          MAGIC_COMMENT_ENABLED = /\A# rbs_inline: enabled\R?\z/ #: Regexp

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

          def rbs_inline_enabled? #: bool
            processed_source.comments.any? { _1.text.match?(MAGIC_COMMENT_ENABLED) }
          end
        end
      end
    end
  end
end
