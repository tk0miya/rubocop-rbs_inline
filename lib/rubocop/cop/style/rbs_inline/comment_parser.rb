# frozen_string_literal: true
# rbs_inline: enabled

require 'rbs/inline'

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

          # Convert byte offset to character offset
          # @rbs byte_offset: Integer
          def character_offset(byte_offset) #: Integer
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[...byte_offset] or raise
            text.force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end

          # Find the leading annotation comment before the given line
          # @rbs def_line: Integer
          def find_leading_annotation(def_line) #: RBS::Inline::AnnotationParser::ParsingResult?
            parsed_comments.find do |r|
              last_comment = r.comments.last or next
              last_comment.location.start_line + 1 == def_line
            end
          end

          # Find annotation comments (#:) before a method definition
          # @rbs def_line: Integer
          def find_annotation_comments(def_line) #: Array[Parser::Source::Comment]?
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

          # Find inline comment on the same line as the method definition
          # @rbs def_line: Integer
          def find_inline_comment(def_line) #: Parser::Source::Comment?
            processed_source.comments.find do |c|
              c.loc.expression.line == def_line && c.text.match?(/\A#:/)
            end
          end

          # Find @rbs return annotation before a method definition
          # @rbs def_line: Integer
          def find_return_annotation(def_line) #: RBS::Inline::AST::Annotations::ReturnType?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            ret = nil #: RBS::Inline::AST::Annotations::ReturnType?
            leading_annotation.each_annotation do |annotation|
              ret = annotation if annotation.is_a?(RBS::Inline::AST::Annotations::ReturnType)
            end
            ret
          end
        end
      end
    end
  end
end
