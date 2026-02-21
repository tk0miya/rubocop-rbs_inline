# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant `@rbs` instance variable type annotation when
        # `attr_*` with an inline type annotation is already defined.
        #
        # When `attr_reader :foo #: Integer` is defined, a separate `# @rbs @foo: Integer`
        # declaration for the instance variable is redundant. RBS::Inline automatically
        # generates the instance variable type from the inline annotation on `attr_*`.
        #
        # @example
        #   # bad
        #   # @rbs @foo: Integer
        #
        #   attr_reader :foo #: Integer
        #
        #   # good
        #   attr_reader :foo #: Integer
        #
        #   # good - no inline annotation, so ivar annotation is not redundant
        #   # @rbs @foo: Integer
        #
        #   attr_reader :foo
        #
        class RedundantInstanceVariableAnnotation < Base
          extend AutoCorrector
          include CommentParser
          include RangeHelp
          include SourceCodeHelper

          MSG = 'Redundant instance variable type annotation. `attr_*` already declares the type inline.'
          ATTRIBUTE_METHODS = %i[attr_reader attr_writer attr_accessor].freeze #: Array[Symbol]

          attr_reader :attributes_scope_stack #: Array[Set[Symbol]]
          attr_reader :ivar_annotations #: Hash[Integer, RBS::Inline::AST::Annotations::IvarType]

          def on_new_investigation #: void
            super
            parse_comments
            @attributes_scope_stack = []
            @ivar_annotations = collect_ivar_annotations
            push_attributes_scope
          end

          def on_investigation_end #: void
            attributes = pop_attributes_scope
            check_offenses(0, Float::INFINITY, attributes)
            super
          end

          # @rbs _node: RuboCop::AST::Node
          def on_class(_node) #: void
            push_attributes_scope
          end

          alias on_module on_class

          # @rbs node: RuboCop::AST::Node
          def after_class(node) #: void
            start_line = node.location.line
            end_line = node.location.end&.line || start_line
            attributes = pop_attributes_scope
            check_offenses(start_line, end_line, attributes)
          end

          alias after_module after_class

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless node.receiver.nil?
            return unless ATTRIBUTE_METHODS.include?(node.method_name)

            register_attribute_method(node)
          end

          private

          def push_attributes_scope #: void
            attributes_scope_stack.push(Set.new)
          end

          def pop_attributes_scope #: Set[Symbol]
            attributes_scope_stack.pop
          end

          def current_attributes_scope #: Set[Symbol]
            attributes_scope_stack.last
          end

          def collect_ivar_annotations #: Hash[Integer, RBS::Inline::AST::Annotations::IvarType]
            result = {} #: Hash[Integer, RBS::Inline::AST::Annotations::IvarType]
            parsed_comments.each do |r|
              r.each_annotation do |annotation|
                next unless annotation.is_a?(RBS::Inline::AST::Annotations::IvarType)

                line = annotation.source.comments.first&.location&.start_line || 0
                result[line] = annotation
              end
            end
            result
          end

          # @rbs start_line: Integer
          # @rbs end_line: Integer | Float
          def extract_ivar_annotations(start_line, end_line) #: Array[RBS::Inline::AST::Annotations::IvarType]
            extracted = [] #: Array[RBS::Inline::AST::Annotations::IvarType]
            ivar_annotations.reject! do |line, annotation|
              next false unless line.between?(start_line, end_line)

              extracted << annotation
              true
            end
            extracted
          end

          # @rbs node: RuboCop::AST::SendNode
          def register_attribute_method(node) #: void
            return unless find_trailing_comment(node.loc.line)

            attribute_names_from(node).each do |name|
              current_attributes_scope.add(:"@#{name}")
            end
          end

          # @rbs start_line: Integer
          # @rbs end_line: Integer | Float
          # @rbs attributes: Set[Symbol]
          def check_offenses(start_line, end_line, attributes) #: void
            extract_ivar_annotations(start_line, end_line).each do |annotation|
              add_ivar_offense(annotation) if attributes.include?(annotation.name)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::IvarType
          def add_ivar_offense(annotation) #: void
            range = annotation_range(annotation) or return
            add_offense(range, message: MSG) do |corrector|
              remove_range = range_by_whole_lines(range, include_final_newline: true)
              remove_range = remove_range.adjust(end_pos: 1) if char_at(remove_range.end_pos) == "\n"
              corrector.remove(remove_range)
            end
          end

          # @rbs node: RuboCop::AST::SendNode
          def attribute_names_from(node) #: Array[Symbol]
            node.arguments.filter_map do |arg|
              arg.value.to_sym if arg.sym_type? || arg.str_type?
            end
          end
        end
      end
    end
  end
end
