# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for the presence or absence of `# rbs_inline:` magic comment.
        #
        # RBS::Inline supports two modes: opt-in (requires `# rbs_inline: enabled`) and
        # opt-out (processes all files by default). This cop enforces consistency in which
        # mode your codebase uses.
        #
        # @example Mode: opt_in
        #   # bad
        #   # (no rbs_inline comment)
        #   class Foo
        #   end
        #
        #   # good
        #   # rbs_inline: enabled
        #   class Foo
        #   end
        #
        #   # good
        #   # rbs_inline: disabled
        #   class Foo
        #   end
        #
        # @example Mode: opt_in, AllowMissingComment: true
        #   # good - the cop does not enforce the magic comment
        #   class Foo
        #   end
        #
        # @example Mode: opt_out
        #   # bad
        #   # rbs_inline: enabled
        #   class Foo
        #   end
        #
        #   # good
        #   # rbs_inline: disabled
        #   class Foo
        #   end
        #
        #   # good
        #   # (no rbs_inline comment)
        #   class Foo
        #   end
        #
        class RequireRbsInlineComment < Base
          include RangeHelp
          extend AutoCorrector

          MSG_MISSING = "Missing `# rbs_inline:` magic comment."
          MSG_FORBIDDEN = "Remove `# rbs_inline:` magic comment."

          # @rbs self.@enforced_style_deprecation_warned: bool

          @enforced_style_deprecation_warned = false # rubocop:disable Style/RbsInline/UntypedInstanceVariable

          def self.enforced_style_deprecation_warned? #: bool
            @enforced_style_deprecation_warned == true
          end

          def self.mark_enforced_style_deprecation_warned! #: void
            @enforced_style_deprecation_warned = true
          end

          def on_new_investigation #: void
            warn_deprecated_enforced_style
            return if processed_source.buffer.source.empty?

            magic_comment = find_rbs_inline_magic_comment
            return if disabled?(magic_comment)

            case effective_mode
            when :opt_in then check_opt_in(magic_comment)
            when :opt_out then check_opt_out(magic_comment)
            end
          end

          private

          def find_rbs_inline_magic_comment #: Parser::Source::Comment?
            processed_source.comments.find do |comment|
              comment.text.match?(/\A# rbs_inline: (enabled|disabled)\R?\z/)
            end
          end

          # @rbs magic_comment: Parser::Source::Comment?
          def disabled?(magic_comment) #: bool
            magic_comment&.text&.match?(/\A# rbs_inline: disabled\R?\z/) || false
          end

          # @rbs magic_comment: Parser::Source::Comment?
          def check_opt_in(magic_comment) #: void
            return if magic_comment
            return if allow_missing_comment?

            insert_position = find_insert_position
            add_offense(first_line_range, message: MSG_MISSING) do |corrector|
              insert_range = Parser::Source::Range.new(processed_source.buffer, insert_position, insert_position)
              corrector.insert_before(insert_range, "# rbs_inline: enabled\n")
            end
          end

          # @rbs magic_comment: Parser::Source::Comment?
          def check_opt_out(magic_comment) #: void
            return unless magic_comment

            add_offense(magic_comment.source_range, message: MSG_FORBIDDEN) do |corrector|
              range = range_with_surrounding_space(magic_comment.source_range, side: :right, newlines: true)
              corrector.remove(range)
            end
          end

          def find_insert_position #: Integer
            first_comment = processed_source.comments.first
            return 0 unless first_comment&.source_range&.first_line == 1

            last_comment_in_block = find_last_comment_in_first_block
            last_comment_in_block.source_range.end_pos + 1
          end

          def find_last_comment_in_first_block #: Parser::Source::Comment
            comments = processed_source.comments
            last_idx = 0

            comments.each_cons(2).with_index do |pair, idx|
              current, following = pair #: [Parser::Source::Comment, Parser::Source::Comment]
              break unless current.source_range.last_line + 1 == following.source_range.first_line

              last_idx = idx + 1
            end

            comments[last_idx] || raise
          end

          def effective_mode #: Symbol
            mode = cop_config["Mode"]&.to_sym
            return mode if %i[opt_in opt_out].include?(mode)

            cop_config["EnforcedStyle"]&.to_sym == :never ? :opt_out : :opt_in
          end

          def allow_missing_comment? #: bool
            cop_config["AllowMissingComment"] == true
          end

          def warn_deprecated_enforced_style #: void
            return if self.class.enforced_style_deprecation_warned?
            return if cop_config["EnforcedStyle"].nil?

            self.class.mark_enforced_style_deprecation_warned!
            Kernel.warn(
              "[rubocop-rbs_inline] Style/RbsInline/RequireRbsInlineComment.EnforcedStyle is deprecated. " \
              "Please migrate to `Style/RbsInline: Mode: opt_in` (was `EnforcedStyle: always`) or " \
              "`Style/RbsInline: Mode: opt_out` (was `EnforcedStyle: never`). " \
              "EnforcedStyle will be removed in the next major version."
            )
          end

          def first_line_range #: Parser::Source::Range
            first_line = processed_source.ast&.source_range&.first_line || 1
            processed_source.buffer.line_range(first_line)
          end
        end
      end
    end
  end
end
