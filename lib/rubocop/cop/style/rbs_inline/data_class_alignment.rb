# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that inline type annotation comments on `Data.define` attributes
        # are aligned to the same column.
        #
        # When multiple attributes have `#:` type annotations, they should all
        # start at the same column position for readability.
        #
        # @example
        #   # bad
        #   MethodEntry = Data.define(
        #     :name, #: Symbol
        #     :node, #: Parser::AST::Node
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
        class DataClassAlignment < Base
          include RangeHelp
          include SourceCodeHelper
          extend AutoCorrector

          MSG = 'Inline type annotation is not aligned.'

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless data_define?(node)
            return if one_liner?(node)

            annotations = collect_annotations(node)
            return if annotations.size < 2

            target_column = annotations.map { _1[:comment].location.column }.max
            annotations.each do |entry|
              comment = entry[:comment]
              next if comment.location.column == target_column

              add_offense(comment) do |corrector|
                correct_alignment(corrector, comment, target_column)
              end
            end
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def data_define?(node) #: bool
            return false unless node.method_name == :define

            node.receiver.is_a?(RuboCop::AST::ConstNode) && node.receiver.short_name == :Data
          end

          # @rbs node: RuboCop::AST::SendNode
          def one_liner?(node) #: bool
            attrs = data_attributes(node)
            first = attrs.first or return false
            last = attrs.last or return false

            first.location.line == last.location.line
          end

          # @rbs node: RuboCop::AST::SendNode
          def data_attributes(node) #: Array[RuboCop::AST::Node]
            node.arguments.select { _1.sym_type? || _1.str_type? }
          end

          # @rbs node: RuboCop::AST::SendNode
          def collect_annotations(node) #: Array[{arg: RuboCop::AST::Node, comment: Parser::Source::Comment}]
            data_attributes(node).filter_map do |arg|
              comment = comment_at(arg.location.line)
              next unless comment&.text&.match?(/\A#:/)

              { arg:, comment: }
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs comment: Parser::Source::Comment
          # @rbs target_column: Integer
          def correct_alignment(corrector, comment, target_column) #: void
            line = comment.location.line
            line_source = processed_source.lines[line - 1] # steep:ignore
            comment_col = comment.location.column
            code_end_col = line_source[...comment_col].rstrip.length
            space_range = build_space_range(line, code_end_col, comment_col)
            padding = [target_column - code_end_col, 1].max
            corrector.replace(space_range, ' ' * padding)
          end

          # @rbs line: Integer
          # @rbs code_end_col: Integer
          # @rbs comment_col: Integer
          def build_space_range(line, code_end_col, comment_col) #: Parser::Source::Range
            line_begin_pos = processed_source.buffer.line_range(line).begin_pos
            range_between(line_begin_pos + code_end_col, line_begin_pos + comment_col)
          end
        end
      end
    end
  end
end
