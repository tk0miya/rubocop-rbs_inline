# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `Data.define` attributes have inline type annotations.
        #
        # Each attribute passed to `Data.define` should have a trailing `#:` type
        # annotation comment on the same line.
        #
        # @example
        #   # bad
        #   MethodEntry = Data.define(:name, :node, :visibility)
        #
        #   # good
        #   MethodEntry = Data.define(
        #     :name,       #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        class MissingDataClassAnnotation < Base
          include MissingClassAnnotation
          extend AutoCorrector

          MSG = "Missing inline type annotation for Data attribute (e.g., `#: Type`)."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            check_missing_annotations(node)
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
