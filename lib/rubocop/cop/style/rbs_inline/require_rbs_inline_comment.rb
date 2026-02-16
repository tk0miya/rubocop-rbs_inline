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
        # @example EnforcedStyle: always (default)
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
        # @example EnforcedStyle: never
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

          MSG_MISSING = 'Missing `# rbs_inline:` magic comment.'
          MSG_FORBIDDEN = 'Remove `# rbs_inline:` magic comment.'

          def on_new_investigation #: void
            return if processed_source.buffer.source.empty?

            magic_comment = find_rbs_inline_magic_comment
            return if disabled?(magic_comment)

            if style == :always
              check_always_style(magic_comment)
            elsif style == :never
              check_never_style(magic_comment)
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
          def check_always_style(magic_comment) #: void
            # disabled is already filtered out by early return
            # magic_comment is either nil or enabled
            return if magic_comment

            # Insert after the first comment block or at the beginning of the file
            insert_position = find_insert_position
            add_offense(first_line_range, message: MSG_MISSING) do |corrector|
              insert_range = Parser::Source::Range.new(processed_source.buffer, insert_position, insert_position)
              corrector.insert_before(insert_range, "# rbs_inline: enabled\n")
            end
          end

          # @rbs magic_comment: Parser::Source::Comment?
          def check_never_style(magic_comment) #: void
            # disabled is already filtered out by early return
            # magic_comment is either nil or enabled
            return unless magic_comment

            add_offense(magic_comment.source_range, message: MSG_FORBIDDEN) do |corrector|
              # Remove the entire line including newline
              range = range_with_surrounding_space(magic_comment.source_range, side: :right, newlines: true)
              corrector.remove(range)
            end
          end

          def find_insert_position #: Integer
            # Find the end of the first comment block (e.g., magic comments)
            # and insert after it
            first_comment = processed_source.comments.first
            # If the first comment doesn't exist or doesn't start at line 1, insert at the beginning
            return 0 unless first_comment&.source_range&.first_line == 1

            last_comment_in_block = find_last_comment_in_first_block
            last_comment_in_block.source_range.end_pos + 1
          end

          def find_last_comment_in_first_block #: Parser::Source::Comment
            comments = processed_source.comments
            last_idx = 0

            comments.each_cons(2).with_index do |(current, following), idx|
              break unless current.source_range.last_line + 1 == following.source_range.first_line

              last_idx = idx + 1
            end

            comments[last_idx]
          end

          def style #: Symbol
            cop_config['EnforcedStyle']&.to_sym || :always
          end

          def first_line_range #: Parser::Source::Range
            # Find the first line of actual code (not comment-only lines)
            # If there's no AST (e.g., file with only comments), use the first line
            first_line = processed_source.ast&.source_range&.first_line || 1
            processed_source.buffer.line_range(first_line)
          end
        end
      end
    end
  end
end
