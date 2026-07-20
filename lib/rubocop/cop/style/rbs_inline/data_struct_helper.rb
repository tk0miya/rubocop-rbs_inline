# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Shared logic for cops that check inline type annotations on struct-like
        # class definitions such as `Data.define` and `Struct.new`.
        #
        # Including cops decide which nodes to check by defining their own matcher
        # (e.g. `struct_like_class?`); this module only provides helpers that operate
        # on an already-matched definition node. Cops may override {#attr_argument?}
        # when the set of attribute arguments differs from the default (e.g.
        # `Struct.new` treats a leading string argument as the struct name rather than
        # an attribute).
        #
        # @rbs module-self RuboCop::Cop::Base
        module DataStructHelper
          include ASTUtils
          include SourceCodeHelper
          include RangeHelp

          # @rbs arg: RuboCop::AST::Node
          def attr_argument?(arg) #: bool
            arg.sym_type? || arg.str_type?
          end

          # @rbs node: RuboCop::AST::SendNode
          def attr_arguments(node) #: Array[RuboCop::AST::Node]
            node.arguments.select { attr_argument?(_1) }
          end

          # @rbs node: RuboCop::AST::SendNode
          def folded?(node) #: bool
            attrs = attr_arguments(node)
            return false if attrs.empty?

            lines = attrs.map { _1.location.line }
            lines.uniq.length < attrs.length || lines.include?(node.location.line)
          end

          # @rbs line: Integer
          def inline_type_annotation?(line) #: boolish
            comment = comment_at(line)
            comment&.text&.match?(/\A#:/)
          end

          # @rbs line: Integer
          def inline_type_comment(line) #: Parser::Source::Comment?
            comment = comment_at(line)
            comment if comment&.text&.match?(/\A#:/)
          end

          # @rbs line: Integer
          def find_regular_comment(line) #: Parser::Source::Comment?
            comment = comment_at(line)
            comment unless comment&.text&.match?(/\A#:/)
          end

          # @rbs node: RuboCop::AST::SendNode
          def annotation_column(node) #: Integer
            last_arg = node.arguments.last
            max_end_col = node.arguments.map do |arg|
              comma_length = arg.equal?(last_arg) ? 0 : 1
              arg.location.column + source!(arg).length + comma_length
            end.max || 0

            max_end_col + 2
          end

          # @rbs node: RuboCop::AST::SendNode
          def longest_argname(node) #: String
            last_index = node.arguments.size - 1
            args = node.arguments.each_with_index.map { |a, i| i < last_index ? "#{a.source}," : a.source.to_s }
            args.max_by(&:length) || ""
          end

          # @rbs node: RuboCop::AST::SendNode
          def build_multiline_replacement(node) #: String # rubocop:disable Metrics/AbcSize
            base_indent = source_code_at(node.location.line)[/\A\s*/]
            last_index = node.arguments.size - 1
            longest = longest_argname(node)

            args_source = node.arguments.each_with_index.map do |arg, i|
              comma = i < last_index ? "," : ""
              prefix = "#{base_indent}  #{arg.source}#{comma}"
              padding = " " * (longest.length - source!(arg).length - comma.length + 2)
              attr_argument?(arg) ? "#{prefix}#{padding}#: untyped" : prefix
            end.join("\n")

            "(\n#{args_source}\n#{base_indent})"
          end
        end
      end
    end
  end
end
