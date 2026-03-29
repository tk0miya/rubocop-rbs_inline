# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        module ASTUtils
          # @rbs node: RuboCop::AST::Node
          # @rbs default: Integer
          def end_line(node, default:) #: Integer
            location = node.location #: untyped
            location.end&.line || default
          end

          # @rbs node: RuboCop::AST::Node
          def name_location(node) #: untyped
            location = node.location #: untyped
            location.name
          end

          # @rbs node: RuboCop::AST::Node
          def source!(node) #: String
            node.source || raise
          end

          #: (RuboCop::AST::SymbolNode) -> Symbol
          #: (RuboCop::AST::StrNode) -> Symbol
          #: (RuboCop::AST::Node) -> Symbol?
          def value_to_sym(node)
            case node
            when RuboCop::AST::SymbolNode
              node.value
            when RuboCop::AST::StrNode
              case (v = node.value)
              when String
                v.to_sym
              else
                value_to_sym(v)
              end
            end
          end
        end
      end
    end
  end
end
