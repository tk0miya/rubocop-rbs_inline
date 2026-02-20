# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant type annotations when multiple type specifications
        # exist for the same method definition.
        #
        # Supports three styles that align with `MissingTypeAnnotation`:
        # - `method_type_signature`: Prefers `#:` annotation comments with full method signature
        # - `doc_style`: Prefers `# @rbs` annotations for both parameters and return types
        # - `doc_style_and_return_annotation`: Prefers `# @rbs` params with trailing `#:` return type
        #
        # @safety
        #   Autocorrection is unsafe because it removes redundant annotations even when
        #   the preferred style annotation is not present. In such cases, the autocorrection
        #   will remove type information, and `MissingTypeAnnotation` will report the missing
        #   annotation that should be added in the preferred style
        #
        # @example EnforcedStyle: method_type_signature
        #   # bad - redundant @rbs parameter annotations
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # bad - redundant trailing return type
        #   #: () -> String
        #   def method(arg) #: String
        #   end
        #
        #   # bad - redundant @rbs return annotation
        #   # @rbs return: String
        #   #: () -> String
        #   def method(arg)
        #   end
        #
        #   # good
        #   #: (Integer) -> String
        #   def method(a)
        #   end
        #
        # @example EnforcedStyle: doc_style
        #   # bad - redundant annotation comment with parameters
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # bad - redundant trailing return type
        #   # @rbs return: String
        #   def method(arg) #: String
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   # @rbs return: String
        #   def method(a)
        #   end
        #
        # @example EnforcedStyle: doc_style_and_return_annotation (default)
        #   # bad - redundant annotation comment with parameters
        #   # @rbs a: Integer
        #   #: (Integer) -> String
        #   def method(a)
        #   end
        #
        #   # bad - redundant @rbs return annotation
        #   # @rbs a: Integer
        #   # @rbs return: String
        #   def method(a) #: String
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   def method(a) #: String
        #   end
        #
        class RedundantTypeAnnotation < Base
          extend AutoCorrector
          include CommentParser
          include ConfigurableEnforcedStyle
          include RangeHelp
          include SourceCodeHelper

          MSG_DOC_STYLE_PARAM = 'Redundant `@rbs` parameter annotation.'
          MSG_DOC_STYLE_RETURN = 'Redundant `@rbs return` annotation.'
          MSG_TRAILING_RETURN = 'Redundant trailing return type annotation.'
          MSG_METHOD_TYPE_SIGNATURE = 'Redundant method type signature.'

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
            check_parameter_redundancy(def_line)
            check_return_type_redundancy(def_line, method_parameter_list_end_line(node))
          end

          # @rbs def_line: Integer
          def check_parameter_redundancy(def_line) #: void
            method_type_signature_comments = find_method_type_signature_comments(def_line)
            param_annotations = find_doc_style_param_annotations(def_line)

            return unless method_type_signature_comments && param_annotations

            # Overload signatures (2+ #: lines) cannot be expressed in doc_style, so always prefer #:
            preferred_style = overload_type_signatures?(def_line) ? :method_type_signature : style

            case preferred_style
            when :method_type_signature
              param_annotations.each { add_offense_for_doc_style_param(_1) }
            when :doc_style, :doc_style_and_return_annotation
              add_offense_for_method_type_signature(method_type_signature_comments)
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

          # @rbs def_line: Integer
          # @rbs parameter_list_end_line: Integer
          def check_return_type_redundancy(def_line, parameter_list_end_line) #: void
            sources = {
              method_type_signature: find_method_type_signature_comments(def_line),
              doc_style_and_return_annotation: find_trailing_comment(parameter_list_end_line),
              doc_style: find_doc_style_return_annotation(def_line)
            }.compact

            return unless sources.size >= 2

            # Overload signatures (2+ #: lines) cannot be expressed in doc_style, so always prefer #:
            preferred_style = overload_type_signatures?(def_line) ? :method_type_signature : style

            sources.each do |type, value|
              add_offense_for_return(type, value) unless type == preferred_style
            end
          end

          # @rbs comments: Array[Parser::Source::Comment]
          def add_offense_for_method_type_signature(comments) #: void
            first = comments.first or return
            last = comments.last or return
            range = first.loc.expression.join(last.loc.expression)
            add_offense(range, message: MSG_METHOD_TYPE_SIGNATURE) do |corrector|
              unexpected_style_detected(:method_type_signature)
              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType
          def add_offense_for_doc_style_param(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_DOC_STYLE_PARAM) do |corrector|
              unexpected_style_detected(:doc_style)
              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

          # @rbs type: Symbol
          # @rbs value: Object
          def add_offense_for_return(type, value) #: void
            case type
            when :method_type_signature
              add_offense_for_method_type_signature(value)
            when :doc_style_and_return_annotation
              add_offense_for_trailing_return(value)
            when :doc_style
              add_offense_for_doc_style_return(value)
            end
          end

          # @rbs comment: Parser::Source::Comment
          def add_offense_for_trailing_return(comment) #: void
            add_offense(comment, message: MSG_TRAILING_RETURN) do |corrector|
              unexpected_style_detected(:return_type_annotation)
              removal_range = range_with_surrounding_space(range: comment.loc.expression, side: :left, newlines: false)
              corrector.remove(removal_range)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          def add_offense_for_doc_style_return(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_DOC_STYLE_RETURN) do |corrector|
              unexpected_style_detected(:doc_style)
              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end
        end
      end
    end
  end
end
