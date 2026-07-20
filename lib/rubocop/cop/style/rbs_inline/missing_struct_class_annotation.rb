# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `Struct.new` attributes have inline type annotations.
        #
        # Each attribute passed to `Struct.new` should have a trailing `#:` type
        # annotation comment on the same line. A leading string argument (the struct
        # name) and the `keyword_init:` keyword argument are not attributes and are
        # ignored.
        #
        # @example
        #   # bad
        #   Point = Struct.new(:x, :y)
        #
        #   # good
        #   Point = Struct.new(
        #     :x,  #: Integer
        #     :y   #: Integer
        #   )
        #
        class MissingStructClassAnnotation < Base
          include MissingClassAnnotation
          extend AutoCorrector

          MSG = "Missing inline type annotation for Struct attribute (e.g., `#: Type`)."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            check_missing_annotations(node)
          end

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
