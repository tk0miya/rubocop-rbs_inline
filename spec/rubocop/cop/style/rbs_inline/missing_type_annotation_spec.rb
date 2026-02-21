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
          ^^^^^^^^^ Missing `@rbs` annotation.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs parameter annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs name: String
          def greet(name)
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has @rbs return annotation' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs return: String
          def greet(name)
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
          ^^^^^^^^^ Missing `@rbs` annotation.
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
          ^^^^^^^^^ Missing `@rbs` annotation.
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
          ^^^^^^^^^ Missing `@rbs` annotation.
            "Hello"
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
          ^^^^^^^^^ Missing `@rbs` params and trailing return type.
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
          ^^^^^^^^^ Missing `@rbs` params and trailing return type.
            "Hello, \#{name}"
          end
        RUBY
      end
    end

    context 'when method has inline #: comment' do
      it 'registers an offense when method has arguments' do
        expect_offense(<<~RUBY)
          def greet(name) #: String
          ^^^^^^^^^ Missing `@rbs` params and trailing return type.
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
          ^^^^^^^^^ Missing `@rbs` params and trailing return type.
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
          ^^^^^^^^^ Missing `@rbs` params and trailing return type.
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

  context 'when IgnoreUnderscoreArguments is true' do
    context 'when EnforcedStyle is doc_style' do
      let(:config) do
        RuboCop::Config.new(
          'Style/RbsInline/MissingTypeAnnotation' => {
            'EnforcedStyle' => 'doc_style',
            'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
            'Visibility' => 'all',
            'IgnoreUnderscoreArguments' => true
          }
        )
      end

      context 'when method has only underscore-prefixed arguments and no annotation' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def greet(_name)
              "Hello"
            end
          RUBY
        end
      end

      context 'when method has only bare underscore argument and no annotation' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def greet(_)
              "Hello"
            end
          RUBY
        end
      end

      context 'when method has mixed arguments and no annotation' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def greet(_unused, name)
            ^^^^^^^^^ Missing `@rbs` annotation.
              "Hello, \#{name}"
            end
          RUBY
        end
      end

      context 'when method has only underscore-prefixed arguments with annotation' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs return: String
            def greet(_name)
              "Hello"
            end
          RUBY
        end
      end

      context 'when method has no arguments and no annotation' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def greet
            ^^^^^^^^^ Missing `@rbs` annotation.
              "Hello"
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
            'Visibility' => 'all',
            'IgnoreUnderscoreArguments' => true
          }
        )
      end

      context 'when method has only underscore-prefixed arguments with trailing #:' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def greet(_name) #: String
              "Hello"
            end
          RUBY
        end
      end

      context 'when method has only underscore-prefixed arguments but no trailing #:' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def greet(_name)
            ^^^^^^^^^ Missing `@rbs` params and trailing return type.
              "Hello"
            end
          RUBY
        end
      end

      context 'when method has mixed arguments with @rbs and trailing #:' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs name: String
            def greet(_unused, name) #: String
              "Hello, \#{name}"
            end
          RUBY
        end
      end

      context 'when method has mixed arguments with no @rbs annotation' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def greet(_unused, name) #: String
            ^^^^^^^^^ Missing `@rbs` params and trailing return type.
              "Hello, \#{name}"
            end
          RUBY
        end
      end
    end

    context 'when EnforcedStyle is method_type_signature' do
      let(:config) do
        RuboCop::Config.new(
          'Style/RbsInline/MissingTypeAnnotation' => {
            'EnforcedStyle' => 'method_type_signature',
            'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation],
            'Visibility' => 'all',
            'IgnoreUnderscoreArguments' => true
          }
        )
      end

      context 'when method has only underscore-prefixed arguments and no annotation' do
        it 'registers an offense (method_type_signature is unaffected)' do
          expect_offense(<<~RUBY)
            def greet(_name)
            ^^^^^^^^^ Missing annotation comment (e.g., `#: (Type) -> ReturnType`).
              "Hello"
            end
          RUBY
        end
      end
    end
  end
end
