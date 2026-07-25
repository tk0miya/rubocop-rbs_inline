# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `#:` inline type annotations in `Struct.new` blocks are aligned.
        #
        # Each `#:` annotation comment should start at the same column, determined by
        # the longest attribute name (plus trailing comma). Folded `Struct.new` calls
        # (where attributes are not one per line) are excluded.
        #
        # @example
        #   # bad
        #   Point = Struct.new(
        #     :x, #: Integer
        #     :y   #: Integer
        #   )
        #
        #   # good
        #   Point = Struct.new(
        #     :x,  #: Integer
        #     :y   #: Integer
        #   )
        #
        class StructClassCommentAlignment < Base
          prepend FileFilter
          include ClassCommentAlignment
          include StructClassMatcher
          extend AutoCorrector

          MSG = "Misaligned inline type annotation for Struct attribute."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            check_comment_alignment(node)
          end
        end
      end
    end
  end
end
