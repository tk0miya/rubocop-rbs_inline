# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for `Data.define` calls with a block.
        #
        # RBS::Inline does not parse the contents of `Data.define` blocks, so any
        # methods defined inside will not be recognized for type checking. Instead,
        # call `Data.define` without a block and define additional methods by
        # reopening the class separately.
        #
        # NOTE: This is a known limitation of RBS::Inline. See
        # https://github.com/soutaro/rbs-inline/pull/183 for the upstream fix.
        #
        # @example
        #   # bad
        #   User = Data.define(:name, :role) do
        #     def admin? = role == :admin #: bool
        #   end
        #
        #   # good
        #   User = Data.define(:name, :role)
        #
        #   class User
        #     def admin? = role == :admin #: bool
        #   end
        #
        class DataDefineWithBlock < Base
          MSG = 'Do not use `Data.define` with a block. RBS::Inline does not parse block contents, ' \
                'so methods defined in the block will not be recognized. ' \
                'Use a separate class definition instead.'

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless data_define?(node)

            block_node = node.parent
            return unless block_node&.block_type?

            add_offense(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def data_define?(node) #: bool
            return false unless node.method_name == :define

            receiver = node.receiver
            receiver.is_a?(RuboCop::AST::ConstNode) && receiver.short_name == :Data
          end
        end
      end
    end
  end
end
