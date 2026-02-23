# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that instance variables in classes/modules have RBS type annotations.
        #
        # Instance variables must either have a `# @rbs @ivar: Type` annotation
        # or be covered by a typed `attr_reader/writer/accessor` declaration.
        #
        # Only instance variables that are **assigned** within the class/module are checked.
        # Read-only references are ignored because the variable may be defined in a parent class.
        #
        # @example
        #   # bad
        #   class Foo
        #     def initialize
        #       @baz = 1
        #     end
        #   end
        #
        #   # good
        #   class Foo
        #     # @rbs @baz: Integer
        #
        #     def initialize
        #       @baz = 1
        #     end
        #   end
        #
        #   # good
        #   class Foo
        #     attr_reader :baz  #: Integer
        #
        #     def initialize
        #       @baz = 1
        #     end
        #   end
        #
        #   # good (only read, may be defined in parent class)
        #   class Foo
        #     def bar
        #       @baz
        #     end
        #   end
        #
        class UntypedInstanceVariable < Base
          include CommentParser
          include RangeHelp

          MSG = 'Instance variable `%<name>s` is not typed. ' \
                'Add `# @rbs %<name>s: Type` or use `attr_* :%<bare_name>s #: Type`.'

          ATTR_METHODS = %i[attr_reader attr_writer attr_accessor].freeze

          # @rbs! type scope = { typed_ivars: Set[Symbol], assigned_ivars: Hash[Symbol, Parser::AST::Node] }

          attr_reader :scope_stack #: Array[scope]
          attr_reader :ivar_type_annotations #: Hash[Integer, Symbol]

          def on_new_investigation #: void
            parse_comments
            @scope_stack = []
            @ivar_type_annotations = collect_ivar_type_annotations
            push_scope
          end

          def on_investigation_end #: void
            ivar_type_annotations.each_value { |name| current_scope[:typed_ivars] << name }
            report_offenses
            pop_scope
          end

          # @rbs _node: Parser::AST::Node
          def on_class(_node) #: void
            push_scope
          end

          alias on_module on_class

          # @rbs node: Parser::AST::Node
          def after_class(node) #: void
            collect_typed_ivars_for_scope(node)
            report_offenses
            pop_scope
          end

          alias after_module after_class

          # @rbs node: Parser::AST::Node
          def on_ivasgn(node) #: void
            name = node.children.first #: Symbol
            current_scope[:assigned_ivars][name] ||= node
          end

          # @rbs node: Parser::AST::Node
          def on_send(node) #: void
            return unless attr_method?(node)

            register_attr_ivars(node)
          end

          private

          # @rbs node: Parser::AST::Node
          def attr_method?(node) #: bool
            node.receiver.nil? && ATTR_METHODS.include?(node.method_name)
          end

          # @rbs node: Parser::AST::Node
          def register_attr_ivars(node) #: void
            node.arguments.each do |arg|
              next unless arg.sym_type? || arg.str_type?

              current_scope[:typed_ivars] << :"@#{arg.value}"
            end
          end

          def push_scope #: void
            scope_stack.push({ typed_ivars: Set.new, assigned_ivars: {} })
          end

          def pop_scope #: void
            scope_stack.pop
          end

          def current_scope #: scope
            scope_stack.last
          end

          # @rbs node: Parser::AST::Node
          def collect_typed_ivars_for_scope(node) #: void
            class_start = node.location.line
            class_end = node.location.end&.line || class_start
            ivar_type_annotations.reject! do |line, name|
              current_scope[:typed_ivars] << name if line.between?(class_start, class_end)
            end
          end

          def collect_ivar_type_annotations #: Hash[Integer, Symbol] # rubocop:disable Metrics/CyclomaticComplexity
            parsed_comments.flat_map { |r| r.each_annotation.to_a }.filter_map do |ann|
              next unless ann.is_a?(RBS::Inline::AST::Annotations::IvarType)
              next if ann.class_instance

              line = ann.source.comments.first&.location&.start_line || 0
              [line, ann.name]
            end.to_h
          end

          def report_offenses #: void
            current_scope[:assigned_ivars].each do |name, node|
              next if current_scope[:typed_ivars].include?(name)

              bare_name = name.to_s.delete_prefix('@')
              add_offense(node.location.name, message: format(MSG, name:, bare_name:))
            end
          end
        end
      end
    end
  end
end
