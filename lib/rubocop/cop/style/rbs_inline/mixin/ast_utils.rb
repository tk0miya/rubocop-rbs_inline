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

          # Returns the arguments node of a method definition.
          # @rbs node: RuboCop::AST::DefNode
          def args_node_for(node) #: RuboCop::AST::Node
            case node.type
            when :def  then node.children[1]
            when :defs then node.children[2]
            else raise
            end
          end

          # Returns the last line of the method parameter list (the closing ) line, or the def line if no parens).
          # @rbs node: RuboCop::AST::DefNode
          def method_parameter_list_end_line(node) #: Integer
            end_line(args_node_for(node), default: node.location.line)
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

          # Returns the name of the constant `node` is assigned to, or `nil` when the name
          # is not statically determinable (e.g. `self::Foo = ...`).
          # @rbs node: RuboCop::AST::Node
          def assigned_constant_name(node) #: String?
            parent = node.parent
            return nil unless parent.is_a?(RuboCop::AST::CasgnNode)
            return nil unless parent.each_path.all? { _1.const_type? || _1.cbase_type? }

            # `const_name` drops the leading `::`, which would name a different constant
            # when the assignment appears inside a namespace.
            parent.absolute? ? "::#{parent.const_name}" : parent.const_name
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
