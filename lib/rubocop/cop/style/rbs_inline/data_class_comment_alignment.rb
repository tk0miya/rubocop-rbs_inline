# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `#:` inline type annotations in `Data.define` blocks are aligned.
        #
        # Each `#:` annotation comment should start at the same column, determined by
        # the longest attribute name (plus trailing comma). Folded `Data.define` calls
        # (where attributes are not one per line) are excluded.
        #
        # @example
        #   # bad
        #   MethodEntry = Data.define(
        #     :name, #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        #   # good
        #   MethodEntry = Data.define(
        #     :name,       #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        class DataClassCommentAlignment < Base
          include RangeHelp
          include SourceCodeHelper
          extend AutoCorrector

          MSG = 'Misaligned inline type annotation for Data attribute.'

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless data_define?(node)
            return if folded_data_class?(node)

            check_annotation_alignment(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def data_define?(node) #: bool
            return false unless node.method_name == :define

            node.receiver.is_a?(RuboCop::AST::ConstNode) && node.receiver.short_name == :Data
          end

          # @rbs arg: RuboCop::AST::Node
          def data_attribute?(arg) #: bool
            arg.sym_type? || arg.str_type?
          end

          # @rbs node: RuboCop::AST::SendNode
          def data_attributes(node) #: Array[RuboCop::AST::Node]
            node.arguments.select { data_attribute?(_1) }
          end

          # @rbs node: RuboCop::AST::SendNode
          def folded_data_class?(node) #: bool
            args = node.arguments
            return false if args.empty?

            lines = args.map { _1.location.line }
            lines.uniq.length < args.length || lines.include?(node.location.line)
          end

          # @rbs node: RuboCop::AST::SendNode
          def check_annotation_alignment(node) #: void
            annotated = data_attributes(node).filter_map do |arg|
              comment = inline_type_comment(arg.location.line)
              [arg, comment] if comment
            end
            return if annotated.size < 2

            expected_col = annotation_column(node)
            annotated.each do |arg, comment|
              actual_col = comment.location.column
              next if actual_col == expected_col

              add_offense(comment.source_range) do |corrector|
                correct_alignment(corrector, arg, comment, expected_col)
              end
            end
          end

          # @rbs line: Integer
          def inline_type_comment(line) #: Parser::Source::Comment?
            comment = comment_at(line)
            comment if comment&.text&.match?(/\A#:/)
          end

          # @rbs node: RuboCop::AST::SendNode
          def annotation_column(node) #: Integer
            last_arg = node.arguments.last
            max_end_col = node.arguments.map do |arg|
              comma_length = arg.equal?(last_arg) ? 0 : 1
              arg.location.column + arg.source.length + comma_length
            end.max || 0 # steep:ignore

            max_end_col + 2
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs arg: RuboCop::AST::Node
          # @rbs comment: Parser::Source::Comment
          # @rbs expected_col: Integer
          def correct_alignment(corrector, arg, comment, expected_col) #: void # rubocop:disable Metrics/AbcSize
            line = arg.location.line
            line_source = source_code_at(line)
            content_end_col = line_source[...comment.location.column].rstrip.length
            padding = [expected_col - content_end_col, 1].max

            line_begin = processed_source.buffer.line_range(line).begin_pos
            replace_start = line_begin + content_end_col
            replace_end = line_begin + comment.location.column

            corrector.replace(range_between(replace_start, replace_end), ' ' * padding)
          end
        end
      end
    end
  end
end
