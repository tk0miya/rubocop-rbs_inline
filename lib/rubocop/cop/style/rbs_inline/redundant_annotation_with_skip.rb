# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant type annotations when `@rbs skip` or `@rbs override` is present.
        #
        # `@rbs skip` tells RBS::Inline to skip RBS generation for this method entirely.
        # `@rbs override` tells RBS::Inline to inherit the type signature from the parent class.
        # In both cases, any additional type annotations (method type signatures, parameter
        # annotations, return type annotations) are redundant and will be ignored by RBS::Inline.
        #
        # @safety
        #   Autocorrection is unsafe because it removes type annotations that may contain
        #   useful documentation even if not used for RBS generation.
        #
        # @example
        #   # bad - redundant method type signature with @rbs skip
        #   # @rbs skip
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # bad - redundant doc-style method type annotation with @rbs skip
        #   # @rbs skip
        #   # @rbs (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # bad - redundant param annotation with @rbs skip
        #   # @rbs skip
        #   # @rbs a: Integer
        #   def method(a)
        #   end
        #
        #   # bad - redundant trailing return type with @rbs skip
        #   # @rbs skip
        #   def method(a) #: void
        #   end
        #
        #   # bad - redundant type annotations with @rbs override
        #   # @rbs override
        #   # @rbs a: Integer
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs skip
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs override
        #   def method(a)
        #   end
        #
        class RedundantAnnotationWithSkip < Base # rubocop:disable Metrics/ClassLength
          extend AutoCorrector
          include CommentParser
          include RangeHelp
          include SourceCodeHelper

          MSG_METHOD_TYPE_SIGNATURE = 'Redundant method type signature. ' \
                                      '`@rbs skip` and `@rbs override` skip RBS generation.'
          MSG_DOC_STYLE_ANNOTATION = 'Redundant `@rbs` annotation. ' \
                                     '`@rbs skip` and `@rbs override` skip RBS generation.'
          MSG_TRAILING_RETURN = 'Redundant trailing return type annotation. ' \
                                '`@rbs skip` and `@rbs override` skip RBS generation.'
          MSG_DUPLICATE_SKIP = 'Duplicate `@rbs skip` annotation.'
          MSG_DUPLICATE_OVERRIDE = 'Duplicate `@rbs override` annotation.'
          MSG_CONFLICTING_SKIP_OVERRIDE = '`@rbs skip` and `@rbs override` cannot both be specified.'

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
            return unless skip_or_override_annotation?(def_line)

            check_skip_override(def_line)
            check_doc_style_annotations(def_line)
            check_trailing_return(method_parameter_list_end_line(node))
          end

          # @rbs line: Integer
          def skip_or_override_annotation?(line) #: bool
            leading_annotation = find_leading_annotation(line)
            return false unless leading_annotation

            leading_annotation.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::Skip, RBS::Inline::AST::Annotations::Override
                return true
              end
            end
            false
          end

          # @rbs def_line: Integer
          def check_skip_override(def_line) #: void
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            first = nil #: (RBS::Inline::AST::Annotations::Skip | RBS::Inline::AST::Annotations::Override)?
            leading_annotation.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::Skip, RBS::Inline::AST::Annotations::Override
                if first.nil?
                  first = annotation
                else
                  msg = skip_override_message(first, annotation)
                  range = annotation_range(annotation) or next
                  add_offense(range, message: msg) do |corrector|
                    corrector.remove(range_by_whole_lines(range, include_final_newline: true))
                  end
                end
              end
            end
          end

          # @rbs first: RBS::Inline::AST::Annotations::Skip | RBS::Inline::AST::Annotations::Override
          # @rbs current: RBS::Inline::AST::Annotations::Skip | RBS::Inline::AST::Annotations::Override
          def skip_override_message(first, current) #: String
            if first.instance_of?(current.class)
              first.is_a?(RBS::Inline::AST::Annotations::Skip) ? MSG_DUPLICATE_SKIP : MSG_DUPLICATE_OVERRIDE
            else
              MSG_CONFLICTING_SKIP_OVERRIDE
            end
          end

          # @rbs def_line: Integer
          def check_doc_style_annotations(def_line) #: void
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            leading_annotation.each_annotation do |annotation|
              msg = doc_style_annotation_message(annotation)
              next unless msg

              range = annotation_range(annotation) or next
              add_offense(range, message: msg) do |corrector|
                corrector.remove(range_by_whole_lines(range, include_final_newline: true))
              end
            end
          end

          # @rbs annotation: untyped
          def doc_style_annotation_message(annotation) #: String?
            case annotation
            when RBS::Inline::AST::Annotations::MethodTypeAssertion
              MSG_METHOD_TYPE_SIGNATURE
            when RBS::Inline::AST::Annotations::Method,
                 RBS::Inline::AST::Annotations::VarType,
                 RBS::Inline::AST::Annotations::BlockType,
                 RBS::Inline::AST::Annotations::ReturnType
              MSG_DOC_STYLE_ANNOTATION
            end
          end

          # @rbs param_list_end_line: Integer
          def check_trailing_return(param_list_end_line) #: void
            comment = find_trailing_comment(param_list_end_line)
            return unless comment

            add_offense(comment, message: MSG_TRAILING_RETURN) do |corrector|
              removal_range = range_with_surrounding_space(range: comment.loc.expression, side: :left, newlines: false)
              corrector.remove(removal_range)
            end
          end

          # Returns the last line of the method parameter list (the closing ) line, or the def line if no parens).
          # @rbs node: Parser::AST::Node
          def method_parameter_list_end_line(node) #: Integer
            args_node = case node.type
                        when :def  then node.children[1]
                        when :defs then node.children[2]
                        else raise
                        end
            args_node.location.end&.line || node.location.line
          end
        end
      end
    end
  end
end
