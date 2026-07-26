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
        #   # good
        #   # rbs_inline: enabled
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

          def on_new_investigation #: void
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
              corrector.insert_before(insert_range, insertion_text(insert_position))
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
            # `end_pos` points at the newline terminating the comment, so `+ 1` moves past it.
            # A file without a trailing newline has none, so clamp to the end of the buffer.
            (last_comment_in_block.source_range.end_pos + 1).clamp(0, processed_source.buffer.source.length)
          end

          # The insert position lands at the end of the buffer when the file has no trailing
          # newline. The magic comment then needs its own newline to stay on a separate line.
          # @rbs insert_position: Integer
          def insertion_text(insert_position) #: String
            source = processed_source.buffer.source
            return "# rbs_inline: enabled\n" if insert_position.zero? || source[insert_position - 1] == "\n"

            "\n# rbs_inline: enabled\n"
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

          def effective_mode #: FileFilter::mode
            mode = cop_config["Mode"]
            if mode
              # `raw.to_s.to_sym` handles YAML-native Integer / Boolean safely.
              sym = mode.to_s.to_sym
              return sym if FileFilter::SUPPORTED_MODES.include?(sym)

              FileFilter.warn_invalid_mode(mode)
            end

            cop_config["EnforcedStyle"]&.to_sym == :never ? :opt_out : :opt_in
          end

          def allow_missing_comment? #: bool
            cop_config["AllowMissingComment"] == true
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
