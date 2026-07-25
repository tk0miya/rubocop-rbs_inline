# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Matcher for `Struct.new` calls, shared by the cops that check `Struct.new`
        # class definitions.
        #
        # Also overrides {DataStructHelper#attr_argument?} for `Struct.new` semantics,
        # so cops that include both must include this module last.
        module StructClassMatcher
          private

          # @rbs node: RuboCop::AST::SendNode
          def struct_like_class?(node) #: bool
            return false unless node.method_name == :new

            (r = node.receiver).is_a?(RuboCop::AST::ConstNode) && r.short_name == :Struct
          end

          # `Struct.new` treats a leading string argument as the struct name, so only
          # symbol arguments are attributes.
          # @rbs arg: RuboCop::AST::Node
          def attr_argument?(arg) #: bool
            arg.sym_type?
          end
        end
      end
    end
  end
end
