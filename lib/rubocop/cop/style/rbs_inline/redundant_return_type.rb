# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant return type annotations when multiple
        # return type specifications exist on the same method definition.
        #
        # Supports three styles:
        # - `method_type_signature`: Prefers `#:` annotation comments before the method
        # - `return_type_annotation`: Prefers inline `#:` return type on the def line
        # - `doc_style`: Prefers `# @rbs return` annotations
        #
        # @example EnforcedStyle: method_type_signature
        #   # bad
        #   #: () -> String
        #   def method(arg) #: String
        #   end
        #
        #   # bad
        #   # @rbs return: String
        #   #: () -> String
        #   def method(arg)
        #   end
        #
        #   # good
        #   #: () -> String
        #   def method(arg)
        #   end
        #
        # @example EnforcedStyle: return_type_annotation (default)
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: String
        #   end
        #
        #   # bad
        #   #: () -> String
        #   def method(arg) #: String
        #   end
        #
        #   # good
        #   def method(arg) #: String
        #   end
        #
        # @example EnforcedStyle: doc_style
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: String
        #   end
        #
        #   # bad
        #   # @rbs return: String
        #   #: () -> String
        #   def method(arg)
        #   end
        #
        #   # good
        #   # @rbs return: String
        #   def method(arg)
        #   end
        #
        class RedundantReturnType < Base
          extend AutoCorrector
          include CommentParser
          include ConfigurableEnforcedStyle
          include RangeHelp

          MSG_RBS_RETURN = 'Redundant `@rbs return` annotation.'
          MSG_INLINE = 'Redundant inline return type annotation.'
          MSG_ANNOTATION = 'Redundant annotation comment.'

          def on_new_investigation #: void
            super
            parse_comments
          end

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            process(node)
          end
          alias on_defs on_def

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            def_line = node.location.line
            sources = {
              method_type_signature: find_annotation_comments(def_line),
              return_type_annotation: find_inline_comment(def_line),
              doc_style: find_return_annotation(def_line)
            }.compact

            unless sources.size >= 2
              correct_style_detected
              return
            end

            correctable = sources.key?(style)
            sources.each do |type, value|
              add_offense_for(type, value, correctable:) unless type == style
            end
          end

          # @rbs type: Symbol
          # @rbs value: Object
          # @rbs correctable: bool
          def add_offense_for(type, value, correctable:) #: void
            case type
            when :method_type_signature
              add_offense_for_annotation(value)
            when :return_type_annotation
              add_offense_for_inline(value, correctable:)
            when :doc_style
              add_offense_for_rbs_return(value, correctable:)
            end
          end

          # @rbs comments: Array[Parser::Source::Comment]
          def add_offense_for_annotation(comments) #: void
            first = comments.first or return
            last = comments.last or return
            range = first.loc.expression.join(last.loc.expression)
            add_offense(range, message: MSG_ANNOTATION) do
              unexpected_style_detected(:method_type_signature)
            end
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs correctable: bool
          def add_offense_for_inline(comment, correctable:) #: void
            add_offense(comment, message: MSG_INLINE) do |corrector|
              unexpected_style_detected(:return_type_annotation)
              next unless correctable

              removal_range = range_with_surrounding_space(range: comment.loc.expression, side: :left, newlines: false)
              corrector.remove(removal_range)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          # @rbs correctable: bool
          def add_offense_for_rbs_return(annotation, correctable:) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_RBS_RETURN) do |corrector|
              unexpected_style_detected(:doc_style)
              next unless correctable

              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end
        end
      end
    end
  end
end
