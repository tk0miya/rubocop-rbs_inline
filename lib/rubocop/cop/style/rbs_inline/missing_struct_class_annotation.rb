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
          prepend FileFilter
          include MissingClassAnnotation
          include StructClassMatcher
          extend AutoCorrector

          MSG = "Missing inline type annotation for Struct attribute (e.g., `#: Type`)."

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless struct_like_class?(node)

            check_missing_annotations(node)
          end
        end
      end
    end
  end
end
