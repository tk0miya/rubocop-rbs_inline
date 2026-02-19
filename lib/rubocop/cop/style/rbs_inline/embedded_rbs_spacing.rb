# frozen_string_literal: true

require_relative 'source_code_helper'
require_relative 'comment_parser'

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
          include SourceCodeHelper
          include CommentParser

          MSG = '`@rbs!` comment must be followed by a blank line.'

          def on_new_investigation #: void
            check_embedded_rbs_spacing
          end

          private

          def check_embedded_rbs_spacing #: void
            parse_comments.each do |result|
              result.each_annotation do |annotation|
                next unless annotation.is_a?(RBS::Inline::AST::Annotations::Embedded)

                check_embedded_annotation(annotation)
              end
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::Embedded
          def check_embedded_annotation(annotation) #: void
            last_comment = annotation.source.comments.last or return
            next_line_number = last_comment.location.start_line + 1

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
