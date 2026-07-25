# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Filters files a cop reports offenses on, based on `Mode` configuration.
        #
        # When `Mode` is `opt_in`, offenses are only reported for files that contain
        # a `# rbs_inline: enabled` magic comment. When `Mode` is `opt_out`, all files
        # are checked unless they contain `# rbs_inline: disabled`. When `Mode` is not
        # set, all files are checked (legacy behavior).
        #
        # This module is designed to be `prepend`ed to a cop so that it can short-circuit
        # the cop's heavy work (annotation parsing via `parse_comments`) and suppress any
        # residual offense reporting for files that should be skipped.
        #
        # @rbs module-self RuboCop::Cop::Base
        module FileFilter
          # @rbs! type mode = :opt_in | :opt_out

          MAGIC_COMMENT_ENABLED  = /\A# rbs_inline: enabled\R?\z/ #: Regexp
          MAGIC_COMMENT_DISABLED = /\A# rbs_inline: disabled\R?\z/ #: Regexp

          SUPPORTED_MODES = %i[opt_in opt_out].freeze #: Array[mode]

          # Tracks Mode values that have already been reported as invalid, so we
          # only emit one warning per typo across the whole rubocop run instead of
          # one per (file × cop).
          # @rbs self.@warned_invalid_modes: Hash[String, bool]

          @warned_invalid_modes = {} # rubocop:disable Style/RbsInline/UntypedInstanceVariable

          # @rbs raw: untyped
          def self.warn_invalid_mode(raw) #: void
            key = raw.to_s
            return if @warned_invalid_modes[key]

            @warned_invalid_modes[key] = true
            Kernel.warn(
              "[rubocop-rbs_inline] Style/RbsInline Mode #{raw.inspect} is not supported. " \
              "Expected one of: #{SUPPORTED_MODES.join(", ")}. Filtering is disabled for this run."
            )
          end

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
            mode = configured_mode
            return false if mode.nil?

            # `# rbs_inline: disabled` always opts a file out, regardless of Mode
            # (matches rbs-inline itself: rbs-inline skips disabled files in both
            # opt_in and opt_out modes).
            return true if rbs_inline_disabled?

            mode == :opt_in && !rbs_inline_enabled?
          end

          def configured_mode #: mode?
            raw = cop_config["Mode"]
            return nil if raw.nil?

            # `raw.to_s.to_sym` handles YAML-native Integer / Boolean without
            # raising NoMethodError on the plain `to_sym`.
            mode = raw.to_s.to_sym
            return mode if SUPPORTED_MODES.include?(mode)

            FileFilter.warn_invalid_mode(raw)
            nil
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
