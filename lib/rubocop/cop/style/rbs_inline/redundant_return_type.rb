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
          extend AutoCorrector
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
            when :annotation_comment
              add_offense_for_annotation(value)
            when :inline_comment
              add_offense_for_inline(value, correctable:)
            when :rbs_return_comment
              add_offense_for_rbs_return(value, correctable:)
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
          # @rbs correctable: bool
          def add_offense_for_inline(comment, correctable:) #: void
            add_offense(comment, message: MSG_INLINE) do |corrector|
              unexpected_style_detected(:inline_comment)
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
              unexpected_style_detected(:rbs_return_comment)
              next unless correctable

              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

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

          # @rbs def_line: Integer
          def find_inline_comment(def_line) #: Parser::Source::Comment?
            processed_source.comments.find do |c|
              c.loc.expression.line == def_line && c.text.match?(/\A#:/)
            end
          end

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

          # @rbs def_line: Integer
          def find_leading_annotation(def_line) #: RBS::Inline::AnnotationParser::ParsingResult?
            result.find do |r|
              last_comment = r.comments.last or next
              last_comment.location.start_line + 1 == def_line
            end
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
