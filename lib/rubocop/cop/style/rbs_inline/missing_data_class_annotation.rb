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
          MSG = 'Missing inline type annotation for Data attribute (e.g., `#: Type`).'

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless data_define?(node)

            node.arguments.each do |arg|
              next unless arg.sym_type?
              next if inline_type_annotation?(arg.location.line)

              add_offense(arg)
            end
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def data_define?(node) #: bool
            return false unless node.method_name == :define

            receiver = node.receiver
            receiver.is_a?(RuboCop::AST::ConstNode) && receiver.short_name == :Data
          end

          # @rbs line: Integer
          def inline_type_annotation?(line) #: bool
            processed_source.comments.any? do |comment|
              comment.location.line == line && comment.text.match?(/\A#:/)
            end
          end
        end
      end
    end
  end
end
