# frozen_string_literal: true

require_relative 'source_code_helper'
require_relative 'comment_parser'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that method-related `@rbs` annotations are placed immediately before method definitions.
        #
        # Method-related annotations (`@rbs param`, `@rbs return`, `@rbs &block`, `@rbs override`,
        # `@rbs skip`, `@rbs %a{...}`, `# @rbs (...) -> Type`, `#: (...) -> Type`) must be placed
        # directly before the method definition they describe, without any blank lines in between.
        # These annotations should not appear in standalone locations without an immediately following
        # method definition.
        #
        # @example
        #   # bad
        #   # @rbs param x: Integer
        #   # @rbs return: String
        #
        #   def method(x)
        #   end
        #
        #   # bad
        #   #: (Integer) -> String
        #
        #   def method(x)
        #   end
        #
        #   # bad
        #   # @rbs param x: Integer
        #   # @rbs return: String
        #   puts "something"
        #
        #   # good
        #   # @rbs param x: Integer
        #   # @rbs return: String
        #   def method(x)
        #   end
        #
        #   # good
        #   #: (Integer) -> String
        #   def method(x)
        #   end
        #
        #   # good
        #   # @rbs x: Integer
        #   private_class_method def self.method(x)
        #   end
        #
        #   # good
        #   # @rbs x: Integer
        #   private def method(x)
        #   end
        #
        class MethodCommentSpacing < Base
          extend AutoCorrector
          include RangeHelp
          include SourceCodeHelper
          include CommentParser

          MSG = 'Method-related `@rbs` annotation must be immediately before a method definition.'
          MSG_WITH_BLANK_LINE = 'Remove blank line between method annotation and method definition.'
          METHOD_DEFINITION_PATTERN =
            /\A(?:(?:private|protected|public|private_class_method|module_function)\s+)?def\s/ #: Regexp

          attr_reader :processed_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          def on_new_investigation #: void
            @processed_comments = []
            parse_comments
            check_method_comment_spacing
          end

          private

          def check_method_comment_spacing #: void
            parsed_comments.each do |comment|
              next if processed_comments.include?(comment)
              next if trailing_comment?(comment)

              check_method_annotation(comment)
            end
          end

          # Check if this is a trailing comment after Ruby code on the same line
          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def trailing_comment?(comment) #: bool
            return false unless comment.comments.size == 1

            first_comment = comment.comments.first or return false
            line_number = first_comment.location.start_line
            line = processed_source.lines[line_number - 1] or return false
            !line[0, first_comment.location.start_column].strip.empty?
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def check_method_annotation(comment) #: void
            return unless method_related_annotation?(comment)

            processed_comments << comment

            last_comment = comment.comments.last or return
            next_line_number = last_comment.location.start_line + 1
            check_spacing_after_annotation(comment, next_line_number)
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def method_related_annotation?(comment) #: bool
            comment.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType
                # VarType includes both parameter types and variable types (@ivar, @@cvar)
                # Only consider it method-related if it's a parameter annotation (name doesn't start with @)
                return true unless annotation.name.start_with?('@')
              when RBS::Inline::AST::Annotations::ReturnType,
                   RBS::Inline::AST::Annotations::BlockType,
                   RBS::Inline::AST::Annotations::Override,
                   RBS::Inline::AST::Annotations::RBSAnnotation,
                   RBS::Inline::AST::Annotations::Skip,
                   RBS::Inline::AST::Annotations::Method,
                   RBS::Inline::AST::Annotations::MethodTypeAssertion
                return true
              end
            end

            false
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          # @rbs next_line_number: Integer
          def check_spacing_after_annotation(comment, next_line_number) #: void
            last_comment = comment.comments.last or return

            if blank_line?(next_line_number)
              check_blank_line_case(last_comment, next_line_number)
            elsif !method_definition_line?(next_line_number) && !skip_only_annotation?(comment)
              range = comment_range(last_comment)
              add_offense(range, message: MSG)
            end
          end

          # @rbs comment: Prism::Comment
          # @rbs blank_line_number: Integer
          def check_blank_line_case(comment, blank_line_number) #: void
            line_after_blank = blank_line_number + 1
            if method_definition_line?(line_after_blank)
              register_blank_line_offense(blank_line_number)
            else
              range = comment_range(comment)
              add_offense(range, message: MSG)
            end
          end

          # @rbs blank_line_number: Integer
          def register_blank_line_offense(blank_line_number) #: void
            range = line_range(blank_line_number)
            add_offense(range, message: MSG_WITH_BLANK_LINE) do |corrector|
              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def skip_only_annotation?(comment) #: bool
            annotations = []
            comment.each_annotation { |a| annotations << a }
            annotations.any? && annotations.all? { |a| a.is_a?(RBS::Inline::AST::Annotations::Skip) }
          end

          # @rbs line_number: Integer
          def method_definition_line?(line_number) #: bool
            METHOD_DEFINITION_PATTERN.match?(source_code_at(line_number).strip)
          end
        end
      end
    end
  end
end
