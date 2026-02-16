# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `@rbs!` comments (embedded RBS) are followed by a blank line.
        #
        # RBS::Inline requires `@rbs!` comments to be standalone comments,
        # meaning they should not have any code immediately following them.
        # A blank line after the `@rbs!` block ensures proper separation.
        #
        # @example
        #   # bad
        #   # @rbs! type foo = Integer
        #   def method
        #   end
        #
        #   # good
        #   # @rbs! type foo = Integer
        #
        #   def method
        #   end
        #
        class EmbeddedRbsSpacing < Base
          extend AutoCorrector

          MSG = '`@rbs!` comment must be followed by a blank line.'

          def on_new_investigation #: void
            check_embedded_rbs_spacing
          end

          private

          def check_embedded_rbs_spacing #: void
            processed_source.comments.each do |comment|
              check_embedded_rbs_comment(comment)
            end
          end

          # @rbs comment: Parser::Source::Comment
          def check_embedded_rbs_comment(comment) #: void
            match = comment.text.match(/\A#(\s+)@rbs!(?:\s+|\Z)/)
            return unless match

            indent = match[1].size
            last_comment_line = find_last_embedded_comment_line(comment, indent)
            next_line_number = last_comment_line.loc.line + 1

            return if blank_line?(next_line_number)

            add_offense(line_range(next_line_number)) do |corrector|
              corrector.insert_before(line_range(next_line_number), "\n")
            end
          end

          # @rbs line_number: Integer
          def blank_line?(line_number) #: bool
            line = processed_source.buffer.source.lines[line_number - 1]
            line.nil? || line.strip.empty?
          end

          # Find the last comment line in an embedded RBS block
          # @rbs start_comment: Parser::Source::Comment
          # @rbs indent: Integer
          def find_last_embedded_comment_line(start_comment, indent) #: Parser::Source::Comment
            start_index = processed_source.comments.index(start_comment)
            return start_comment unless start_index

            last_comment = start_comment
            current_line = start_comment.loc.line

            processed_source.comments.drop(start_index + 1).each do |comment|
              # Must be consecutive lines
              break if comment.loc.line != current_line + 1

              # Must match the embedded pattern: indented or blank comment
              break unless comment.text.match?(/\A#(\s{#{indent + 1},}.*|\s*)\Z/)

              last_comment = comment
              current_line = comment.loc.line
            end

            last_comment
          end

          # @rbs line_number: Integer
          def line_range(line_number) #: Parser::Source::Range
            processed_source.buffer.line_range(line_number)
          end
        end
      end
    end
  end
end
