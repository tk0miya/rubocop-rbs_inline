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
        # - `annotation_comment`: Prefers `#:` annotation comments before the method
        # - `inline_comment`: Prefers inline `#:` return type on the def line
        # - `rbs_return_comment`: Prefers `# @rbs return` annotations
        #
        # @example EnforcedStyle: annotation_comment
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
        # @example EnforcedStyle: inline_comment (default)
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
        # @example EnforcedStyle: rbs_return_comment
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
        class RedundantReturnType < Base # rubocop:disable Metrics/ClassLength
          include ConfigurableEnforcedStyle
          include RangeHelp

          MSG_RBS_RETURN = 'Redundant `@rbs return` annotation.'
          MSG_INLINE = 'Redundant inline return type annotation.'
          MSG_ANNOTATION = 'Redundant annotation comment.'

          attr_reader :result #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          def on_new_investigation #: void
            super
            @result = parse_comments
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
              annotation_comment: find_annotation_comments(def_line),
              inline_comment: find_inline_comment(def_line),
              rbs_return_comment: find_return_annotation(def_line)
            }.compact

            unless sources.size >= 2
              correct_style_detected
              return
            end

            sources.each do |type, value|
              add_offense_for(type, value) unless type == style
            end
          end

          # @rbs type: Symbol
          # @rbs value: Object
          def add_offense_for(type, value) #: void
            case type
            when :annotation_comment
              add_offense_for_annotation(value)
            when :inline_comment
              add_offense_for_inline(value)
            when :rbs_return_comment
              add_offense_for_rbs_return(value)
            end
          end

          # @rbs comments: Array[Parser::Source::Comment]
          def add_offense_for_annotation(comments) #: void
            first = comments.first or return
            last = comments.last or return
            range = first.loc.expression.join(last.loc.expression)
            add_offense(range, message: MSG_ANNOTATION) do
              unexpected_style_detected(:annotation_comment)
            end
          end

          # @rbs comment: Parser::Source::Comment
          def add_offense_for_inline(comment) #: void
            add_offense(comment, message: MSG_INLINE) do
              unexpected_style_detected(:inline_comment)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          def add_offense_for_rbs_return(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_RBS_RETURN) do
              unexpected_style_detected(:rbs_return_comment)
            end
          end

          # @rbs def_line: Integer
          def find_annotation_comments(def_line) #: Array[Parser::Source::Comment]?
            comments = [] #: Array[Parser::Source::Comment]
            line = def_line - 1
            while line.positive?
              comment = processed_source.comments.find { |c| c.loc.expression.line == line }
              break if comment.nil? || !standalone_comment?(comment)

              comments.unshift(comment) if comment.text.match?(/\A#:/)
              line -= 1
            end
            comments.empty? ? nil : comments
          end

          # @rbs def_line: Integer
          def find_inline_comment(def_line) #: Parser::Source::Comment?
            processed_source.comments.find do |c|
              c.loc.expression.line == def_line && c.text.match?(/\A#:/)
            end
          end

          # @rbs def_line: Integer
          def find_return_annotation(def_line) #: RBS::Inline::AST::Annotations::ReturnType?
            comment_lines = contiguous_comment_lines_above(def_line)
            parsing_result = result.find do |r|
              r.comments.map(&:location).map(&:start_line).intersect?(comment_lines)
            end
            return unless parsing_result

            ret = nil #: RBS::Inline::AST::Annotations::ReturnType?
            parsing_result.each_annotation do |annotation|
              ret = annotation if annotation.is_a?(RBS::Inline::AST::Annotations::ReturnType)
            end
            ret
          end

          # @rbs comment: Parser::Source::Comment
          def standalone_comment?(comment) #: bool
            line_text = processed_source.lines[comment.loc.expression.line - 1]
            line_text.strip.start_with?('#')
          end

          # @rbs def_line: Integer
          def contiguous_comment_lines_above(def_line) #: Array[Integer]
            lines = [] #: Array[Integer]
            line = def_line - 1
            while line.positive?
              break unless processed_source.comments.any? { |c| c.loc.expression.line == line }

              lines << line
              line -= 1
            end
            lines
          end

          def parse_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]
            parsed_result = Prism.parse(processed_source.buffer.source)
            RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          # @rbs byte_offset: Integer
          def character_offset(byte_offset) #: Integer
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[...byte_offset] or raise
            text.force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end
        end
      end
    end
  end
end
