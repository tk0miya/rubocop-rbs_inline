# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for `Struct.new` calls with a block.
        #
        # RBS::Inline does not parse the contents of `Struct.new` blocks, so any
        # methods defined inside will not be recognized for type checking. Instead,
        # call `Struct.new` without a block and define additional methods by
        # reopening the class separately.
        #
        # @example
        #   # bad
        #   User = Struct.new(:name, :role) do
        #     def admin? = role == :admin #: bool
        #   end
        #
        #   # good
        #   User = Struct.new(:name, :role)
        #
        #   class User
        #     def admin? = role == :admin #: bool
        #   end
        #
        class StructNewWithBlock < Base
          MSG = "Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, " \
                "so methods defined in the block will not be recognized. " \
                "Use a separate class definition instead."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            block_node = node.parent
            return unless block_node&.block_type?

            add_offense(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def struct_like_class?(node) #: bool
            return false unless node.method_name == :new

            (r = node.receiver).is_a?(RuboCop::AST::ConstNode) && r.short_name == :Struct
          end
        end
      end
    end
  end
end
