# frozen_string_literal: true

require "rbs/inline"

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that instance variables in classes/modules have RBS type annotations.
        #
        # Instance variables must either have a `# @rbs @ivar: Type` annotation
        # or be covered by a typed `attr_reader/writer/accessor` declaration.
        # Class-level (singleton) instance variables, assigned inside `class << self`
        # or `def self.x`, must be annotated with `# @rbs self.@ivar: Type` instead.
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
        #   # good (class-level ivar annotated with `self.@`)
        #   class Foo
        #     # @rbs self.@instance: Foo
        #
        #     def self.instance
        #       @instance ||= new
        #     end
        #   end
        #
        class UntypedInstanceVariable < Base
          prepend FileFilter
          include ASTUtils
          include CommentParser
          include RangeHelp

          MSG_IVAR = "Instance variable `%<name>s` is not typed. " \
                     "Add `# @rbs %<name>s: Type` or use `attr_* :%<bare_name>s #: Type`."
          MSG_CIVAR = "Class instance variable `%<name>s` is not typed. " \
                      "Add `# @rbs self.%<name>s: Type` or use `attr_* :%<bare_name>s #: Type`."

          ATTR_METHODS = %i[attr_reader attr_writer attr_accessor].freeze

          # @rbs! type scope = {
          #     typed_ivars: Set[Symbol],
          #     typed_class_ivars: Set[Symbol],
          #     assigned_ivars: Hash[Symbol, RuboCop::AST::Node],
          #     assigned_class_ivars: Hash[Symbol, RuboCop::AST::Node],
          #     singleton_depth: Integer
          #   }

          attr_reader :scope_stack #: Array[scope]
          attr_reader :ivar_type_annotations #: Hash[Integer, Symbol]
          attr_reader :civar_type_annotations #: Hash[Integer, Symbol]

          def on_new_investigation #: void
            parse_comments
            @scope_stack = []
            @ivar_type_annotations, @civar_type_annotations = collect_ivar_type_annotations
            push_scope
          end

          def on_investigation_end #: void
            ivar_type_annotations.each_value { current_scope[:typed_ivars] << _1 }
            civar_type_annotations.each_value { current_scope[:typed_class_ivars] << _1 }
            report_offenses
            pop_scope
          end

          # @rbs _node: RuboCop::AST::Node
          def on_class(_node) #: void
            push_scope
          end

          alias on_module on_class

          # @rbs node: RuboCop::AST::Node
          def after_class(node) #: void
            collect_typed_ivars_for_scope(node)
            report_offenses
            pop_scope
          end

          alias after_module after_class

          # @rbs _node: RuboCop::AST::Node
          def on_sclass(_node) #: void
            current_scope[:singleton_depth] += 1
          end
          alias on_defs on_sclass

          # @rbs _node: RuboCop::AST::Node
          def after_sclass(_node) #: void
            current_scope[:singleton_depth] -= 1
          end
          alias after_defs after_sclass

          # @rbs node: RuboCop::AST::Node
          def on_ivasgn(node) #: void
            name = node.children.first #: Symbol
            if singleton_context?
              current_scope[:assigned_class_ivars][name] ||= node
            else
              current_scope[:assigned_ivars][name] ||= node
            end
          end

          # @rbs node: RuboCop::AST::SendNode
          def on_send(node) #: void
            return unless attr_method?(node)

            register_attr_ivars(node)
          end

          private

          # @rbs node: RuboCop::AST::SendNode
          def attr_method?(node) #: bool
            node.receiver.nil? && ATTR_METHODS.include?(node.method_name)
          end

          # @rbs node: RuboCop::AST::SendNode
          def register_attr_ivars(node) #: void
            typed = singleton_context? ? current_scope[:typed_class_ivars] : current_scope[:typed_ivars]
            node.arguments.each do |arg|
              case arg
              when RuboCop::AST::SymbolNode, RuboCop::AST::StrNode
                typed << :"@#{arg.value}"
              end
            end
          end

          def push_scope #: void
            scope_stack.push({
                               typed_ivars: Set.new,
                               typed_class_ivars: Set.new,
                               assigned_ivars: {},
                               assigned_class_ivars: {},
                               singleton_depth: 0
                             })
          end

          def pop_scope #: void
            scope_stack.pop
          end

          def current_scope #: scope
            scope_stack.last || raise
          end

          def singleton_context? #: bool
            current_scope[:singleton_depth].positive?
          end

          # @rbs node: RuboCop::AST::Node
          def collect_typed_ivars_for_scope(node) #: void
            class_start = node.location.line
            class_end = end_line(node, default: class_start)
            ivar_type_annotations.reject! do |line, name|
              current_scope[:typed_ivars] << name if line.between?(class_start, class_end)
            end
            civar_type_annotations.reject! do |line, name|
              current_scope[:typed_class_ivars] << name if line.between?(class_start, class_end)
            end
          end

          def collect_ivar_type_annotations #: [Hash[Integer, Symbol], Hash[Integer, Symbol]]
            ivar = {} #: Hash[Integer, Symbol]
            civar = {} #: Hash[Integer, Symbol]
            parsed_comments.flat_map { _1.each_annotation.to_a }.each do |ann|
              next unless ann.is_a?(RBS::Inline::AST::Annotations::IvarType)

              if ann.class_instance
                civar[annotation_line(ann)] = ann.name
              else
                ivar[annotation_line(ann)] = ann.name
              end
            end
            [ivar, civar]
          end

          # @rbs ann: RBS::Inline::AST::Annotations::IvarType
          def annotation_line(ann) #: Integer
            ann.source.comments.first&.location&.start_line || 0
          end

          def report_offenses #: void
            report_untyped(current_scope[:assigned_ivars], current_scope[:typed_ivars], MSG_IVAR)
            report_untyped(current_scope[:assigned_class_ivars], current_scope[:typed_class_ivars], MSG_CIVAR)
          end

          # @rbs assigned: Hash[Symbol, RuboCop::AST::Node]
          # @rbs typed: Set[Symbol]
          # @rbs message_template: String
          def report_untyped(assigned, typed, message_template) #: void
            assigned.each do |name, node|
              next if typed.include?(name)

              bare_name = name.to_s.delete_prefix("@")
              add_offense(name_location(node), message: format(message_template, name:, bare_name:))
            end
          end
        end
      end
    end
  end
end
