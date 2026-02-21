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

          METHOD_TYPE_SIGNATURE_MESSAGE = 'Missing annotation comment (e.g., `#: (Type) -> ReturnType`).'
          DOC_STYLE_PARAM_MESSAGE = 'Missing `@rbs %<name>s:` annotation.'
          DOC_STYLE_RETURN_MESSAGE = 'Missing `@rbs return:` annotation.'
          DOC_STYLE_TRAILING_RETURN_MESSAGE = 'Missing trailing return type annotation (e.g., `#: void`).'
          ATTRIBUTE_METHOD_MESSAGE = 'Missing inline type annotation (e.g., `#: Type`).'

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
            check_method_entries
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
            check_method_entries
            visibility_stack.pop
            unannotated_methods_stack.pop
          end

          alias after_module after_class
          alias after_sclass after_class

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
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

          def check_method_entries #: void
            current_method_entries.each do |entry|
              next unless target_node?(entry.visibility)

              if entry.node.def_type? || entry.node.defs_type?
                check_def(entry.node)
              else
                check_attribute_method(entry.node)
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def check_def(node) #: void
            line = node.location.line
            return if skip_annotation?(line)
            # Overload signatures (2+ #: lines) are always valid regardless of style,
            # because overloads cannot be expressed in doc_style format.
            return if overload_type_signatures?(line)

            case style
            when :method_type_signature
              check_method_type_signature(node)
            when :doc_style
              check_method_parameters_in_doc_style(node)
              check_return_type_in_doc_style(node)
            when :doc_style_and_return_annotation
              check_method_parameters_in_doc_style(node)
              check_return_type_in_return_annotation(node)
            end
          end

          # @rbs node: Parser::AST::Node
          def check_method_type_signature(node) #: void
            return if find_method_type_signature_comments(node.location.line)

            add_offense(offense_range_for_def(node), message: METHOD_TYPE_SIGNATURE_MESSAGE)
          end

          # @rbs node: Parser::AST::Node
          def check_method_parameters_in_doc_style(node) #: void # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
            line = node.location.line
            param_annotations = find_doc_style_param_annotations(line)
            annotated_names = param_annotations ? param_annotations.map { doc_style_annotation_name(_1) } : []

            args_node_for(node).children.each do |argument|
              name = argument.children[0]&.to_s
              next if name.nil? || name.start_with?('_')

              candidates = param_candidate_names(argument, name)
              next unless candidates
              next if candidates.any? { annotated_names.include?(_1) }

              add_offense(argument, message: format(DOC_STYLE_PARAM_MESSAGE, name: param_display_name(argument)))
            end
          end

          # @rbs node: Parser::AST::Node
          def check_return_type_in_doc_style(node) #: void
            return if find_doc_style_return_annotation(node.location.line)

            add_offense(offense_range_for_def(node), message: DOC_STYLE_RETURN_MESSAGE)
          end

          # @rbs node: Parser::AST::Node
          def check_return_type_in_return_annotation(node) #: void
            return if find_trailing_comment(method_parameter_list_end_line(node))

            add_offense(offense_range_for_def(node), message: DOC_STYLE_TRAILING_RETURN_MESSAGE)
          end

          # @rbs node: Parser::AST::Node
          def check_attribute_method(node) #: void
            return if annotated_attribute_method?(node.location.line)

            add_offense(node, message: ATTRIBUTE_METHOD_MESSAGE)
          end

          # Returns the last line of the method parameter list (the closing ) line, or the def line if no parens).
          # @rbs node: Parser::AST::Node
          def method_parameter_list_end_line(node) #: Integer
            args_node_for(node).location.end&.line || node.location.line
          end

          # @rbs node: Parser::AST::Node
          def args_node_for(node) #: Parser::AST::Node
            case node.type
            when :defs then node.children[2]
            else node.children[1]
            end
          end

          # @rbs line: Integer
          def annotated_attribute_method?(line) #: boolish
            # attr_* always requires inline comment regardless of style
            find_trailing_comment(line)
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType | RBS::Inline::AST::Annotations::SplatParamType | RBS::Inline::AST::Annotations::DoubleSplatParamType # rubocop:disable Layout/LineLength
          def doc_style_annotation_name(annotation) #: String
            case annotation
            when RBS::Inline::AST::Annotations::BlockType
              "&#{annotation.name}"
            when RBS::Inline::AST::Annotations::SplatParamType
              annotation.name ? "*#{annotation.name}" : '*'
            when RBS::Inline::AST::Annotations::DoubleSplatParamType
              annotation.name ? "**#{annotation.name}" : '**'
            else
              annotation.name.to_s
            end
          end

          # @rbs line: Integer
          def skip_annotation?(line) #: bool
            annotation = find_leading_annotation(line)
            return false unless annotation

            annotation.comments.any? { |c| c.location.slice.match?(/\A#\s+@rbs\s+(skip|override)\b/) }
          end

          # Returns acceptable annotation name variants for the parameter, or nil for unrecognized types.
          # @rbs argument: Parser::AST::Node
          # @rbs name: String
          def param_candidate_names(argument, name) #: Array[String]?
            case argument.type
            when :arg, :optarg, :kwarg, :kwoptarg then [name]
            when :restarg then ["*#{name}", '*']
            when :kwrestarg then ["**#{name}", '**']
            when :blockarg then ['&', "&#{name}"]
            end
          end

          # Returns the display name for a parameter node, used in offense messages.
          # @rbs argument: Parser::AST::Node
          def param_display_name(argument) #: String
            name = argument.children[0].to_s
            case argument.type
            when :restarg then "*#{name}"
            when :kwrestarg then "**#{name}"
            when :blockarg then "&#{name}"
            else name
            end
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
