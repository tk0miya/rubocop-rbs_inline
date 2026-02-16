# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `@rbs` variable comments are followed by a blank line.
        #
        # RBS::Inline requires `@rbs` comments for instance variables, class variables,
        # and class instance variables to be standalone comments, meaning they should
        # not have any code immediately following them. A blank line after the variable
        # comment ensures proper separation.
        #
        # @example
        #   # bad
        #   # @rbs @ivar: Integer
        #   # @rbs @@cvar: Float
        #   # @rbs self.@civar: String
        #   def method
        #   end
        #
        #   # good
        #   # @rbs @ivar: Integer
        #   # @rbs @@cvar: Float
        #   # @rbs self.@civar: String
        #
        #   def method
        #   end
        #
        class VariableCommentSpacing < Base
          extend AutoCorrector

          MSG = '`@rbs` variable comment must be followed by a blank line.'
          VARIABLE_COMMENT_PATTERN = /\A#\s+@rbs\s+(?:self\.)?@@?[a-zA-Z_]/

          def on_new_investigation #: void
            check_variable_comment_spacing
          end

          private

          def check_variable_comment_spacing #: void
            processed_source.comments.each do |comment|
              check_variable_comment(comment)
            end
          end

          # @rbs comment: Parser::Source::Comment
          def check_variable_comment(comment) #: void
            # Match @rbs comments for variables: @ivar, @@cvar, self.@civar
            match = comment.text.match(VARIABLE_COMMENT_PATTERN)
            return unless match

            last_comment_line = find_last_variable_comment_line(comment)
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

          # Find the last comment line in a variable comment block
          # @rbs start_comment: Parser::Source::Comment
          def find_last_variable_comment_line(start_comment) #: Parser::Source::Comment
            start_index = processed_source.comments.index(start_comment)
            return start_comment unless start_index

            last_comment = start_comment
            current_line = start_comment.loc.line

            processed_source.comments.drop(start_index + 1).each do |comment|
              # Must be consecutive lines
              break if comment.loc.line != current_line + 1

              # Must be another @rbs variable comment
              break unless comment.text.match?(VARIABLE_COMMENT_PATTERN)

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
