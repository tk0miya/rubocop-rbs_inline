# frozen_string_literal: true

require 'rbs/inline'

require_relative 'source_code_helper'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Utility module for parsing RBS inline comments
        # @rbs module-self RuboCop::Cop::Base
        module CommentParser
          attr_reader :parsed_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          # Parse comments from the source code
          def parse_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]
            parsed_result = Prism.parse(processed_source.buffer.source)
            @parsed_comments = RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          # Find the last comment in a consecutive block starting from start_comment
          # @rbs start_comment: Parser::Source::Comment
          # @rbs &block: (Parser::Source::Comment) -> bool
          def find_last_consecutive_comment(start_comment, &block) #: Parser::Source::Comment
            start_index = processed_source.comments.index(start_comment)
            return start_comment unless start_index

            last_comment = start_comment
            current_line = start_comment.loc.line

            processed_source.comments.drop(start_index + 1).each do |comment|
              break if comment.loc.line != current_line + 1
              break unless block.call(comment)

              last_comment = comment
              current_line = comment.loc.line
            end

            last_comment
          end

          # Find the leading annotation comment before the given line
          # @rbs def_line: Integer
          def find_leading_annotation(def_line) #: RBS::Inline::AnnotationParser::ParsingResult?
            parsed_comments.find do |r|
              last_comment = r.comments.last or next
              next unless last_comment.location.start_line + 1 == def_line

              # Exclude trailing inline comments (e.g., `def method = value #: Type`)
              # by verifying all comment lines contain only whitespace before '#'
              r.comments.all? { |c| processed_source.buffer.source_line(c.location.start_line).match?(/\A\s*#/) }
            end
          end

          # Find method type signature comments (#:) before a method definition
          # @rbs def_line: Integer
          def find_method_type_signature_comments(def_line) #: Array[Parser::Source::Comment]?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            annotation_lines = leading_annotation.comments
                                                 .select { |c| c.location.slice.start_with?('#:') }
                                                 .map { |c| c.location.start_line }
            return if annotation_lines.empty?

            comments = processed_source.comments.select do |c|
              annotation_lines.include?(c.loc.expression.line)
            end
            comments.empty? ? nil : comments
          end

          # Find trailing comment on the same line as the method definition
          # @rbs line: Integer
          def find_trailing_comment(line) #: Parser::Source::Comment?
            processed_source.comments.find do |c|
              c.loc.expression.line == line && c.text.match?(/\A#:/)
            end
          end

          # Find @rbs parameter annotations before a method definition
          # @rbs def_line: Integer
          def find_doc_style_param_annotations(def_line) #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]?
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

          # Find @rbs return annotation before a method definition
          # @rbs def_line: Integer
          def find_doc_style_return_annotation(def_line) #: RBS::Inline::AST::Annotations::ReturnType?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            ret = nil #: RBS::Inline::AST::Annotations::ReturnType?
            leading_annotation.each_annotation do |annotation|
              ret = annotation if annotation.is_a?(RBS::Inline::AST::Annotations::ReturnType)
            end
            ret
          end

          # Returns true if there are 2 or more leading #: method type signature lines (overloads).
          # Overloads cannot be expressed in doc_style format, so they take precedence over style config.
          # @rbs def_line: Integer
          def overload_type_signatures?(def_line) #: bool
            comments = find_method_type_signature_comments(def_line)
            comments.is_a?(Array) && comments.size >= 2
          end
        end
      end
    end
  end
end
