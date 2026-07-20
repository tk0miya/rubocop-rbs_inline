# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `#:` inline type annotations in `Data.define` blocks are aligned.
        #
        # Each `#:` annotation comment should start at the same column, determined by
        # the longest attribute name (plus trailing comma). Folded `Data.define` calls
        # (where attributes are not one per line) are excluded.
        #
        # @example
        #   # bad
        #   MethodEntry = Data.define(
        #     :name, #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        #   # good
        #   MethodEntry = Data.define(
        #     :name,       #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        class DataClassCommentAlignment < Base
          include ClassCommentAlignment
          extend AutoCorrector

          MSG = "Misaligned inline type annotation for Data attribute."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            check_comment_alignment(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def struct_like_class?(node) #: bool
            return false unless node.method_name == :define

            (r = node.receiver).is_a?(RuboCop::AST::ConstNode) && r.short_name == :Data
          end
        end
      end
    end
  end
end
