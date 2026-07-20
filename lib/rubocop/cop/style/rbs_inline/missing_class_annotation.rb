# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Shared behavior for cops that ensure struct-like class attributes have
        # inline type annotations (`Data.define` / `Struct.new`).
        #
        # The including cop matches the definition node (e.g. via `struct_like_class?`)
        # and calls {#check_missing_annotations}.
        #
        # @rbs module-self RuboCop::Cop::Base
        module MissingClassAnnotation
          include DataStructHelper

          # @rbs node: RuboCop::AST::SendNode
          def check_missing_annotations(node) #: void
            if folded?(node)
              add_offenses_for_folded(node)
            else
              check_multiline(node)
            end
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def add_offenses_for_folded(node) #: void
            corrected = false
            attr_arguments(node).each do |arg|
              if corrected
                add_offense(arg)
              else
                replacement = build_multiline_replacement(node)
                loc = node.loc
                if loc.begin && loc.end
                  add_offense(arg) { _1.replace(loc.begin.join(loc.end), replacement) }
                  corrected = true
                end
              end
            end
          end

          # @rbs node: RuboCop::AST::SendNode
          def check_multiline(node) #: void
            attr_arguments(node).each do |arg|
              next if inline_type_annotation?(arg.location.line)

              add_offense(arg) { correct_multiline(_1, node, arg) }
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs node: RuboCop::AST::SendNode
          # @rbs arg: RuboCop::AST::Node
          def correct_multiline(corrector, node, arg) #: void
            existing_comment = find_regular_comment(arg.location.line)

            if existing_comment
              comment_text = existing_comment.text.sub(/\A#\s*/, "")
              corrector.replace(existing_comment.source_range, "#: untyped -- #{comment_text}")
            else
              insert_annotation(corrector, node, arg)
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs node: RuboCop::AST::SendNode
          # @rbs arg: RuboCop::AST::Node
          def insert_annotation(corrector, node, arg) #: void
            line = arg.location.line
            line_source = source_code_at(line)
            content_end_col = line_source.rstrip.length
            padding = [annotation_column(node) - content_end_col, 1].max || raise
            line_begin = processed_source.buffer.line_range(line).begin_pos
            insert_pos = line_begin + content_end_col

            corrector.insert_before(range_between(insert_pos, insert_pos), "#{" " * padding}#: untyped")
          end
        end
      end
    end
  end
end
