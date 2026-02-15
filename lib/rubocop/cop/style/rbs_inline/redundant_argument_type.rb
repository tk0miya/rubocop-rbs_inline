# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant argument type annotations when both
        # annotation comments (`#:`) and `@rbs` parameter comments
        # specify argument types for the same method.
        #
        # Supports two styles:
        # - `method_type_signature`: Prefers `#:` annotation comments with parameter types
        # - `doc_style`: Prefers `# @rbs param:` annotations for parameter types
        #
        # @example EnforcedStyle: method_type_signature
        #   # bad
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   def method(a) #: void
        #   end
        #
        # @example EnforcedStyle: doc_style (default)
        #   # bad
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   def method(a) #: void
        #   end
        #
        #   # good
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        class RedundantArgumentType < Base
          extend AutoCorrector
          include CommentParser
          include ConfigurableEnforcedStyle
          include RangeHelp

          MSG_RBS_PARAM = 'Redundant `@rbs` parameter annotation.'
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
            annotation_comments = find_annotation_comments(def_line)
            param_annotations = find_param_annotations(def_line)

            unless annotation_comments && param_annotations
              correct_style_detected
              return
            end

            case style
            when :method_type_signature
              param_annotations.each { add_offense_for_rbs_param(_1) }
            when :doc_style
              add_offense_for_annotation(annotation_comments)
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

          # @rbs annotation: RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType
          def add_offense_for_rbs_param(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_RBS_PARAM) do |corrector|
              unexpected_style_detected(:doc_style)
              next unless style == :method_type_signature

              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

          # @rbs def_line: Integer
          def find_param_annotations(def_line) #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            annotations = [] #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]
            leading_annotation.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType, RBS::Inline::AST::Annotations::BlockType
                annotations << annotation
              end
            end
            annotations.empty? ? nil : annotations
          end
        end
      end
    end
  end
end
