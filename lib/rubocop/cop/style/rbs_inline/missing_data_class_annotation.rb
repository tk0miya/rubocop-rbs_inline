# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that `Data.define` attributes have inline type annotations.
        #
        # Each attribute passed to `Data.define` should have a trailing `#:` type
        # annotation comment on the same line.
        #
        # @example
        #   # bad
        #   MethodEntry = Data.define(:name, :node, :visibility)
        #
        #   # good
        #   MethodEntry = Data.define(
        #     :name,       #: Symbol
        #     :node,       #: Parser::AST::Node
        #     :visibility  #: Symbol
        #   )
        #
        class MissingDataClassAnnotation < Base
          include RangeHelp
          include SourceCodeHelper
          extend AutoCorrector

          MSG = 'Missing inline type annotation for Data attribute (e.g., `#: Type`).'

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless data_define?(node)

            if folded_data_class?(node)
              add_offenses_for_folded_data_class(node)
            else
              check_multiline_data_class(node)
            end
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

          # @rbs line: Integer
          def inline_type_annotation?(line) #: boolish
            comment = comment_at(line)
            comment&.text&.match?(/\A#:/)
          end

          # @rbs node: RuboCop::AST::SendNode
          def folded_data_class?(node) #: bool
            attrs = data_attributes(node)
            return false if attrs.empty?

            lines = attrs.map { _1.location.line }
            lines.uniq.length < attrs.length || lines.include?(node.location.line)
          end

          # @rbs node: RuboCop::AST::SendNode
          def add_offenses_for_folded_data_class(node) #: void
            corrected = false
            data_attributes(node).each do |arg|
              if corrected
                add_offense(arg)
              else
                replacement = build_multiline_replacement(node)
                add_offense(arg) { |corrector| corrector.replace(node.loc.begin.join(node.loc.end), replacement) }
                corrected = true
              end
            end
          end

          # @rbs node: RuboCop::AST::SendNode
          def longest_argname(node) #: String
            last_index = node.arguments.size - 1
            args = node.arguments.each_with_index.map { |a, i| i < last_index ? "#{a.source}," : a.source }
            args.max_by(&:length) || ''
          end

          # @rbs node: RuboCop::AST::SendNode
          def build_multiline_replacement(node) #: String # rubocop:disable Metrics/AbcSize
            base_indent = source_code_at(node.location.line)[/\A\s*/]
            last_index = node.arguments.size - 1
            longest = longest_argname(node)

            args_source = node.arguments.each_with_index.map do |arg, i|
              comma = i < last_index ? ',' : ''
              prefix = "#{base_indent}  #{arg.source}#{comma}"
              padding = ' ' * (longest.length - arg.source.length - comma.length + 2)
              data_attribute?(arg) ? "#{prefix}#{padding}#: untyped" : prefix
            end.join("\n")

            "(\n#{args_source}\n#{base_indent})"
          end

          # @rbs node: RuboCop::AST::SendNode
          def check_multiline_data_class(node) #: void
            data_attributes(node).each do |arg|
              next if inline_type_annotation?(arg.location.line)

              add_offense(arg) { |corrector| correct_multiline(corrector, node, arg) }
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs node: RuboCop::AST::SendNode
          # @rbs arg: RuboCop::AST::Node
          def correct_multiline(corrector, node, arg) #: void
            existing_comment = find_regular_comment(arg.location.line)

            if existing_comment
              comment_text = existing_comment.text.sub(/\A#\s*/, '')
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
            padding = [annotation_column(node) - content_end_col, 1].max
            line_begin = processed_source.buffer.line_range(line).begin_pos
            insert_pos = line_begin + content_end_col

            corrector.insert_before(range_between(insert_pos, insert_pos), "#{' ' * padding}#: untyped")
          end

          # @rbs node: RuboCop::AST::SendNode
          def annotation_column(node) #: Integer
            last_arg = node.arguments.last
            max_end_col = data_attributes(node).map do |arg|
              comma_length = arg.equal?(last_arg) ? 0 : 1
              arg.location.column + arg.source.length + comma_length
            end.max || 0 # steep:ignore

            max_end_col + 2
          end

          # @rbs line: Integer
          def find_regular_comment(line) #: Parser::Source::Comment?
            comment = comment_at(line)
            comment unless comment&.text&.match?(/\A#:/)
          end
        end
      end
    end
  end
end
