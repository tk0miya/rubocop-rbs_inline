# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks that method definitions and `attr_*` declarations have
        # RBS inline type annotations.
        #
        # The `EnforcedStyle` option determines which annotation format is required:
        #
        # - `method_type_signature`: Requires `#:` annotation comments only
        # - `doc_style`: Requires `# @rbs` annotations
        # - `doc_style_and_return_annotation`: Requires `# @rbs` parameters and trailing `#:` return type
        #
        # The `Visibility` option determines which methods to check:
        #
        # - `all`: Checks all methods regardless of visibility (default)
        # - `public`: Only checks public methods and `attr_*` declarations
        #
        # Methods annotated with `# @rbs skip` are always excluded from inspection.
        #
        # @example EnforcedStyle: method_type_signature
        #   # bad
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # bad
        #   attr_reader :name
        #
        #   # good
        #   #: (String) -> String
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # good
        #   #: String
        #   attr_reader :name
        #
        # @example EnforcedStyle: doc_style
        #   # bad
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # bad
        #   attr_reader :name
        #
        #   # good
        #   # @rbs name: String
        #   # @rbs return: String
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # good
        #   # @rbs name: String
        #   attr_reader :name
        #
        # @example EnforcedStyle: doc_style_and_return_annotation
        #   # bad - no annotation
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # bad - missing trailing return type
        #   # @rbs name: String
        #   def greet(name)
        #     "Hello, #{name}"
        #   end
        #
        #   # good - @rbs parameters + trailing return type
        #   # @rbs name: String
        #   def greet(name) #: String
        #     "Hello, #{name}"
        #   end
        #
        #   # good - attr with trailing type
        #   attr_reader :name #: String
        #
        class MissingTypeAnnotation < Base # rubocop:disable Metrics/ClassLength
          include CommentParser
          include ConfigurableEnforcedStyle
          include RangeHelp

          MESSAGES = {
            method_type_signature: 'Missing annotation comment (e.g., `#: (Type) -> ReturnType`).',
            doc_style: 'Missing `@rbs` annotation.',
            doc_style_and_return_annotation: 'Missing `@rbs` params and trailing return type.'
          }.freeze

          ATTR_MESSAGE = 'Missing inline type annotation (e.g., `#: Type`).'

          ATTR_METHODS = %i[attr_reader attr_writer attr_accessor].freeze
          VISIBILITY_MODIFIERS = %i[public protected private].freeze

          # @rbs! type visibility = :public | :protected | :private

          MethodEntry = Data.define(
            :name,       #: Symbol
            :node,       #: Parser::AST::Node
            :visibility  #: visibility
          )

          attr_reader :visibility_stack #: Array[visibility]
          attr_reader :unannotated_methods_stack #: Array[Array[MethodEntry]]

          def on_new_investigation #: void
            super
            parse_comments
            @visibility_stack = [:public]
            @unannotated_methods_stack = [[]]
          end

          def on_investigation_end #: void
            report_offenses
            super
          end

          # @rbs _node: Parser::AST::Node
          def on_class(_node) #: void
            visibility_stack.push(:public)
            unannotated_methods_stack.push([])
          end

          alias on_module on_class
          alias on_sclass on_class

          # @rbs _node: Parser::AST::Node
          def after_class(_node) #: void
            report_offenses
            visibility_stack.pop
            unannotated_methods_stack.pop
          end

          alias after_module after_class
          alias after_sclass after_class

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            return if annotated_def?(node)

            current_method_entries << MethodEntry.new(
              name: node.method_name, node:, visibility: current_visibility(node)
            )
          end

          alias on_defs on_def

          # @rbs node: Parser::AST::Node
          def on_send(node) #: void
            return unless node.receiver.nil?

            method_name = node.method_name
            if VISIBILITY_MODIFIERS.include?(method_name)
              on_visibility_modifier(node)
            elsif ATTR_METHODS.include?(method_name)
              on_attribute_method(node)
            end
          end

          private

          # Returns the method entries for the current scope (class/module)
          def current_method_entries #: Array[MethodEntry]
            unannotated_methods_stack.last
          end

          # @rbs node: Parser::AST::Node
          def on_visibility_modifier(node) #: void
            if node.arguments.empty?
              visibility_stack[-1] = node.method_name
            else
              names = node.arguments.filter_map { |arg| arg.value.to_sym if arg.sym_type? || arg.str_type? }
              current_method_entries.map! do |entry|
                names.include?(entry.name) ? entry.with(visibility: node.method_name) : entry
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def on_attribute_method(node) #: void
            return if annotated_attr?(node.location.line)

            node.arguments.each do |arg|
              next unless arg.sym_type? || arg.str_type?

              current_method_entries << MethodEntry.new(
                name: arg.value.to_sym, node:, visibility: current_visibility(node)
              )
            end
          end

          # @rbs node: Parser::AST::Node
          def current_visibility(node) #: visibility
            if node.parent&.send_type? && VISIBILITY_MODIFIERS.include?(node.parent.method_name)
              # method definition with visibility (ex. private def foo)
              node.parent.method_name
            else
              visibility_stack.last
            end
          end

          # @rbs visibility: visibility
          def target_node?(visibility) #: bool
            return true if cop_config['Visibility'] == 'all'

            visibility == :public
          end

          def report_offenses #: void
            msg = MESSAGES[style]
            current_method_entries.each do |entry|
              next unless target_node?(entry.visibility)

              if entry.node.def_type? || entry.node.defs_type?
                add_offense(offense_range_for_def(entry.node), message: msg)
              else
                add_offense(entry.node, message: ATTR_MESSAGE)
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def annotated_def?(node) #: boolish
            line = node.location.line
            return true if skip_annotation?(line)

            case style
            when :method_type_signature
              find_method_type_signature_comments(line)
            when :doc_style
              rbs_annotations?(line)
            when :doc_style_and_return_annotation
              # Inline comment is always required for return type.
              # For multi-line signatures, the trailing #: comment may be on the closing ) line.
              trailing = find_trailing_comment(method_parameter_list_end_line(node))
              trailing && (node.arguments.empty? || rbs_annotations?(line))
            end
          end

          # Returns the last line of the method parameter list (the closing ) line, or the def line if no parens).
          # @rbs node: Parser::AST::Node
          def method_parameter_list_end_line(node) #: Integer
            args_node = case node.type
                        when :def  then node.children[1]
                        when :defs then node.children[2]
                        else raise
                        end
            args_node.location.end&.line || node.location.line
          end

          # @rbs line: Integer
          def annotated_attr?(line) #: boolish
            # attr_* always requires inline comment regardless of style
            find_trailing_comment(line)
          end

          # @rbs line: Integer
          def rbs_annotations?(line) #: bool
            annotation = find_leading_annotation(line)
            return false unless annotation

            annotation.comments.any? { |c| c.location.slice.match?(/\A#\s+@rbs\b/) }
          end

          # @rbs line: Integer
          def skip_annotation?(line) #: bool
            annotation = find_leading_annotation(line)
            return false unless annotation

            annotation.comments.any? { |c| c.location.slice.match?(/\A#\s+@rbs\s+(skip|override)\b/) }
          end

          # @rbs node: Parser::AST::Node
          def offense_range_for_def(node) #: Parser::Source::Range
            range_between(
              node.location.keyword.begin_pos,
              node.location.name.end_pos
            )
          end
        end
      end
    end
  end
end
