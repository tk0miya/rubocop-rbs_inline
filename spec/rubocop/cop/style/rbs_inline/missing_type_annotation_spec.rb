# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::MissingTypeAnnotation, :config do
  context 'when EnforcedStyle is method_type_signature' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'method_type_signature',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
          'Visibility' => 'public'
        }
      )
    end

    context 'when method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name)
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has #: annotation comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has multi-line #: annotation comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String)
          #:   -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has inline #: comment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name) #: String
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has only @rbs annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          # @rbs return: String
          def greet(name)
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when singleton method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def self.greet(name)
          ^^^^^^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when singleton method has #: annotation comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          def self.greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when attr_reader has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_reader has #: annotation comment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          #: String
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_reader has inline #: comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          attr_reader :name #: String
        RUBY
      end
    end

    context 'when attr_writer has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          attr_writer :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_accessor has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          attr_accessor :name
          ^^^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when method has @rbs skip annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs skip
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs override annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs override
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is doc_style' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'doc_style',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
          'Visibility' => 'public'
        }
      )
    end

    context 'when method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name)
                    ^^^^ Missing `@rbs name:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has only @rbs parameter annotation without return' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          def greet(name)
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs return annotation but no parameter annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def greet(name)
                    ^^^^ Missing `@rbs name:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs parameter and return annotations' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs name: String
          # @rbs return: String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs annotation but missing some arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          def greet(name, age)
                          ^^^ Missing `@rbs age:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has only #: annotation comment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          #: (String) -> String
          def greet(name)
                    ^^^^ Missing `@rbs name:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has overload #: annotation comments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          #: (Integer) -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has only inline #: comment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name) #: String
                    ^^^^ Missing `@rbs name:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when attr_reader has @rbs annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_reader has only inline #: comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          attr_reader :name #: String
        RUBY
      end
    end

    context 'when method has no arguments and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet
          ^^^^^^^^^ Missing `@rbs return:` annotation.
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has *args and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(*args)
                    ^^^^^ Missing `@rbs *args:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
          end
        RUBY
      end
    end

    context 'when method has *args with @rbs *args annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs *args: String
          # @rbs return: void
          def greet(*args)
          end
        RUBY
      end
    end

    context 'when method has *args with @rbs * annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs *: String
          # @rbs return: void
          def greet(*args)
          end
        RUBY
      end
    end

    context 'when method has anonymous * and return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: void
          def greet(*)
          end
        RUBY
      end
    end

    context 'when method has *_args (underscore-prefixed) and return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: void
          def greet(*_args)
          end
        RUBY
      end
    end

    context 'when method has **opts and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(**opts)
                    ^^^^^^ Missing `@rbs **opts:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
          end
        RUBY
      end
    end

    context 'when method has **opts with @rbs **opts annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs **opts: String
          # @rbs return: void
          def greet(**opts)
          end
        RUBY
      end
    end

    context 'when method has **opts with @rbs ** annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs **: String
          # @rbs return: void
          def greet(**opts)
          end
        RUBY
      end
    end

    context 'when method has anonymous ** and return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: void
          def greet(**)
          end
        RUBY
      end
    end

    context 'when method has **_opts (underscore-prefixed) and return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: void
          def greet(**_opts)
          end
        RUBY
      end
    end

    context 'when method has &block and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(&block)
                    ^^^^^^ Missing `@rbs &block:` annotation.
          ^^^^^^^^^ Missing `@rbs return:` annotation.
          end
        RUBY
      end
    end

    context 'when method has &block with @rbs &block annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs &block: (String) -> void
          # @rbs return: void
          def greet(&block)
          end
        RUBY
      end
    end

    context 'when method has &block with @rbs & annotation and return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs &: (String) -> void
          # @rbs return: void
          def greet(&block)
          end
        RUBY
      end
    end

    context 'when method has &_block (underscore-prefixed) and return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: void
          def greet(&_block)
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is doc_style_and_return_annotation' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'doc_style_and_return_annotation',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
          'Visibility' => 'public'
        }
      )
    end

    context 'when method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name)
                    ^^^^ Missing `@rbs name:` annotation.
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          def greet(name)
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has inline #: comment' do
      it 'registers an offense when method has arguments' do
        expect_offense(<<~RUBY)
          def greet(name) #: String
                    ^^^^ Missing `@rbs name:` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end

      it 'does not register an offense when method has no arguments' do
        expect_no_offenses(<<~RUBY)
          def greet #: String
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has #: annotation comment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          #: (String) -> String
          def greet(name)
                    ^^^^ Missing `@rbs name:` annotation.
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has overload #: annotation comments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          #: (Integer) -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs and inline #:' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs name: String
          def greet(name) #: String
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when attr_reader has inline #: comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          attr_reader :name #: String
        RUBY
      end
    end

    context 'when attr_reader has @rbs annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_reader has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when method has @rbs annotation but missing some arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          def greet(name, age) #: String
                          ^^^ Missing `@rbs age:` annotation.
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has all arguments annotated with trailing #:' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs name: String
          # @rbs age: Integer
          def greet(name, age) #: String
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has multi-line signature with @rbs and trailing #: on closing ) line' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs a: String
          # @rbs b: Integer
          def greet(
            a,
            b
          ) #: void
            a + b.to_s
          end
        RUBY
      end
    end

    context 'when method has multi-line signature with @rbs but no trailing #:' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs a: String
          # @rbs b: Integer
          def greet(
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
            a,
            b
          )
            a + b.to_s
          end
        RUBY
      end
    end

    context 'when method has multi-line signature with inline comment on def line and #: on closing ) line' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs a: String
          # @rbs b: Integer
          def greet( # some comment
            a,
            b
          ) #: void
            a + b.to_s
          end
        RUBY
      end
    end

    context 'when method has *args and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(*args)
                    ^^^^^ Missing `@rbs *args:` annotation.
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
          end
        RUBY
      end
    end

    context 'when method has *args with @rbs *args annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs *args: String
          def greet(*args) #: void
          end
        RUBY
      end
    end

    context 'when method has *args with @rbs * annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs *: String
          def greet(*args) #: void
          end
        RUBY
      end
    end

    context 'when method has anonymous * and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet(*) #: void
          end
        RUBY
      end
    end

    context 'when method has *_args (underscore-prefixed) and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet(*_args) #: void
          end
        RUBY
      end
    end

    context 'when method has **opts and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(**opts)
                    ^^^^^^ Missing `@rbs **opts:` annotation.
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
          end
        RUBY
      end
    end

    context 'when method has **opts with @rbs **opts annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs **opts: String
          def greet(**opts) #: void
          end
        RUBY
      end
    end

    context 'when method has **opts with @rbs ** annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs **: String
          def greet(**opts) #: void
          end
        RUBY
      end
    end

    context 'when method has anonymous ** and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet(**) #: void
          end
        RUBY
      end
    end

    context 'when method has **_opts (underscore-prefixed) and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet(**_opts) #: void
          end
        RUBY
      end
    end

    context 'when method has &block and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(&block)
                    ^^^^^^ Missing `@rbs &block:` annotation.
          ^^^^^^^^^ Missing trailing return type annotation (e.g., `#: void`).
          end
        RUBY
      end
    end

    context 'when method has &block with @rbs &block annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs &block: (String) -> void
          def greet(&block) #: void
          end
        RUBY
      end
    end

    context 'when method has &block with @rbs & annotation and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs &: (String) -> void
          def greet(&block) #: void
          end
        RUBY
      end
    end

    context 'when method has &_block (underscore-prefixed) and inline return' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet(&_block) #: void
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is method_type_signature_or_return_annotation' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'method_type_signature_or_return_annotation',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation
                                  method_type_signature_or_return_annotation],
          'Visibility' => 'public'
        }
      )
    end

    context 'when method has arguments and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name)
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has arguments and method_type_signature' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has arguments and trailing return annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet(name) #: String
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has arguments and doc_style annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs name: String
          # @rbs return: String
          def greet(name)
          ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has no arguments and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def greet
          ^^^^^^^^^ Missing type annotation (e.g., `#: -> ReturnType` or trailing `#: ReturnType`).
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has no arguments and method_type_signature' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: -> String
          def greet
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has no arguments and trailing return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def greet #: String
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has no arguments and doc_style annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs return: String
          def greet
          ^^^^^^^^^ Missing type annotation (e.g., `#: -> ReturnType` or trailing `#: ReturnType`).
            "Hello"
          end
        RUBY
      end
    end

    context 'when method has overload #: annotation comments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (String) -> String
          #: (Integer) -> String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs skip annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs skip
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when singleton method has arguments and no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def self.greet(name)
          ^^^^^^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when singleton method has no arguments and trailing return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def self.greet #: String
            "Hello"
          end
        RUBY
      end
    end

    context 'when attr_reader has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          attr_reader :name
          ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
        RUBY
      end
    end

    context 'when attr_reader has inline #: comment' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          attr_reader :name #: String
        RUBY
      end
    end
  end

  context 'when Visibility is public' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'method_type_signature',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
          'Visibility' => 'public'
        }
      )
    end

    context 'when private method has no annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            private

            def greet(name)
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when protected method has no annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            protected

            def greet(name)
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when inline private method has no annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            private def greet(name)
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when public method after private has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            private

            def private_method
            end

            public

            def public_method
            ^^^^^^^^^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
            end
          end
        RUBY
      end
    end

    context 'when private attr_reader has no annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            private

            attr_reader :name
          end
        RUBY
      end
    end

    context 'when inline private attr_reader has no annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            private attr_reader :name
          end
        RUBY
      end
    end

    context 'when method is made private after definition' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            def greet(name)
              "Hello, \#{name}"
            end
            private :greet
          end
        RUBY
      end
    end

    context 'when attr_reader is made private after definition' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            attr_reader :name
            private :name
          end
        RUBY
      end
    end

    context 'when nested class resets visibility' do
      it 'registers an offense for public method in nested class' do
        expect_offense(<<~RUBY)
          class Outer
            private

            class Inner
              def greet
              ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              end
            end

            def outer_method
            end
          end
        RUBY
      end
    end

    context 'when nested module resets visibility' do
      it 'registers an offense for public method in nested module' do
        expect_offense(<<~RUBY)
          class Outer
            private

            module Inner
              def greet
              ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              end
            end
          end
        RUBY
      end
    end
  end

  context 'when Visibility is all' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/MissingTypeAnnotation' => {
          'EnforcedStyle' => 'method_type_signature',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
          'Visibility' => 'all'
        }
      )
    end

    context 'when private method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            private

            def greet(name)
            ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when inline private method has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            private def greet(name)
                    ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when private method has annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            private

            #: (String) -> String
            def greet(name)
              "Hello, \#{name}"
            end
          end
        RUBY
      end
    end

    context 'when private attr_reader has no annotation' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            private

            attr_reader :name
            ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
          end
        RUBY
      end
    end

    context 'when method is made private after definition' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            def greet(name)
            ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              "Hello, \#{name}"
            end
            private :greet
          end
        RUBY
      end
    end

    context 'when attr_reader is made private after definition' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            attr_reader :name
            ^^^^^^^^^^^^^^^^^ Missing inline type annotation (e.g., `#: Type`).
            private :name
          end
        RUBY
      end
    end
  end
end
