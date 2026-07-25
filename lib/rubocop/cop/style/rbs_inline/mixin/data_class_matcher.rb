# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Matcher for `Data.define` calls, shared by the cops that check
        # `Data.define` class definitions.
        module DataClassMatcher
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
