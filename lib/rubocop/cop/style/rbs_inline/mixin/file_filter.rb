# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Filters files a cop reports offenses on, based on `Mode` configuration.
        #
        # When `Mode` is `opt_in`, offenses are only reported for files that contain
        # a `# rbs_inline: enabled` magic comment. When `Mode` is `opt_out`, all files
        # are checked unless they contain `# rbs_inline: disabled`.
        #
        # This module is designed to be `prepend`ed to a cop so that it can short-circuit
        # the cop's heavy work (annotation parsing via `parse_comments`) and suppress any
        # residual offense reporting for files that should be skipped.
        #
        # @rbs module-self RuboCop::Cop::Base
        module FileFilter
          include ModeConfig

          MAGIC_COMMENT_ENABLED  = /\A# rbs_inline: enabled\R?\z/ #: Regexp
          MAGIC_COMMENT_DISABLED = /\A# rbs_inline: disabled\R?\z/ #: Regexp

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

          # Exposes the FileFilter's per-file skip decision as a proper method so
          # helper modules (e.g. `CommentParser`) can consult it explicitly instead
          # of poking at `@rbs_inline_skip_file` directly.
          def rbs_inline_file_skipped? #: bool
            @rbs_inline_skip_file == true
          end

          private

          def skip_by_mode? #: bool
            # `# rbs_inline: disabled` always opts a file out, regardless of Mode
            # (matches rbs-inline itself: rbs-inline skips disabled files in both
            # opt_in and opt_out modes).
            return true if rbs_inline_disabled?

            configured_mode == :opt_in && !rbs_inline_enabled?
          end

          # Iterate the already-materialized `processed_source.comments` so this
          # matches RequireRbsInlineComment's detection exactly (line endings,
          # indented comments, heredoc/string content are all handled correctly
          # by the parser).
          def rbs_inline_enabled? #: bool
            processed_source.comments.any? { _1.text.match?(MAGIC_COMMENT_ENABLED) }
          end

          def rbs_inline_disabled? #: bool
            processed_source.comments.any? { _1.text.match?(MAGIC_COMMENT_DISABLED) }
          end
        end
      end
    end
  end
end
