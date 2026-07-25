# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Shared behavior for cops that ensure `#:` inline type annotations on
        # struct-like class attributes (`Data.define` / `Struct.new`) are aligned.
        #
        # The including cop matches the definition node (e.g. via `struct_like_class?`)
        # and calls {#check_comment_alignment}.
        #
        # @rbs module-self RuboCop::Cop::Base
        module ClassCommentAlignment
          include DataStructHelper

          # @rbs node: RuboCop::AST::SendNode
          def check_comment_alignment(node) #: void
            return if folded?(node)

            check_annotation_alignment(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def check_annotation_alignment(node) #: void
            annotated = attr_arguments(node).filter_map do |arg|
              comment = inline_type_comment(arg.location.line)
              [arg, comment] if comment #: [RuboCop::AST::Node, Parser::Source::Comment]
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

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs arg: RuboCop::AST::Node
          # @rbs comment: Parser::Source::Comment
          # @rbs expected_col: Integer
          def correct_alignment(corrector, arg, comment, expected_col) #: void # rubocop:disable Metrics/AbcSize
            line = arg.location.line
            line_source = source_code_at(line)
            source = line_source[...comment.location.column] || raise
            content_end_col = source.rstrip.length
            padding = [expected_col - content_end_col, 1].max || raise

            line_begin = processed_source.buffer.line_range(line).begin_pos
            replace_start = line_begin + content_end_col
            replace_end = line_begin + comment.location.column

            corrector.replace(range_between(replace_start, replace_end), " " * padding)
          end
        end
      end
    end
  end
end
