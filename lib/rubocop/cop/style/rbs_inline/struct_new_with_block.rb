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
          prepend FileFilter
          include StructClassMatcher
          include ASTUtils

          MSG = "Do not use `Struct.new` with a block. RBS::Inline does not parse block contents, " \
                "so methods defined in the block will not be recognized. Keep the `Struct.new` call " \
                "and move the methods into %<destination>s."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            block_node = node.parent
            return unless block_node&.block_type?

            add_offense(node, message: format(MSG, destination: destination(block_node)))
          end

          private

          # The constant the definition is assigned to is the class to reopen.
          # @rbs node: RuboCop::AST::Node
          def destination(node) #: String
            class_name = assigned_constant_name(node)
            return "a `class` that reopens it" unless class_name

            "`class #{class_name} ... end` written after it"
          end
        end
      end
    end
  end
end
