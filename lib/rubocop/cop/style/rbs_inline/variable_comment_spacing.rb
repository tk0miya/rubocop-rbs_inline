# frozen_string_literal: true

require_relative 'source_code_helper'
require_relative 'comment_parser'

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
          include SourceCodeHelper
          include CommentParser

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
            return unless comment.text.match?(VARIABLE_COMMENT_PATTERN)

            last_comment_line = find_last_consecutive_comment(comment) { |c| c.text.match?(VARIABLE_COMMENT_PATTERN) }
            next_line_number = last_comment_line.loc.line + 1

            return if blank_line?(next_line_number)

            add_offense(line_range(next_line_number)) do |corrector|
              corrector.insert_before(line_range(next_line_number), "\n")
            end
          end
        end
      end
    end
  end
end
