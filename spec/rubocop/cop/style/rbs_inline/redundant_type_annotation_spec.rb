# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantTypeAnnotation, :config do
  context 'when EnforcedStyle is method_type_signature' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantTypeAnnotation' => {
          'EnforcedStyle' => 'method_type_signature',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation]
        }
      )
    end

    context 'with parameter type redundancy' do
      context 'when both #: with params and # @rbs param: are present' do
        it 'registers an offense on the # @rbs param: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            #: (Integer) -> void
            def method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: (Integer) -> void
            def method(a)
            end
          RUBY
        end
      end

      context 'when both #: with params and # @rbs param: are present on a singleton method' do
        it 'registers an offense on the # @rbs param: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            #: (Integer) -> void
            def self.method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: (Integer) -> void
            def self.method(a)
            end
          RUBY
        end
      end

      context 'when multiple # @rbs param: annotations are present' do
        it 'registers an offense on each # @rbs param: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            # @rbs b: String
            ^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            #: (Integer, String) -> void
            def method(a, b)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: (Integer, String) -> void
            def method(a, b)
            end
          RUBY
        end
      end

      context 'when # @rbs &block: and #: with block are present' do
        it 'registers an offense on the # @rbs &block: annotation' do
          expect_offense(<<~RUBY)
            # @rbs &block: () -> void
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            #: () { () -> void } -> void
            def method(&block)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: () { () -> void } -> void
            def method(&block)
            end
          RUBY
        end
      end

      context 'when only #: with params is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: (Integer) -> void
            def method(a)
            end
          RUBY
        end
      end

      context 'when only # @rbs param: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs a: Integer
            def method(a) #: void
            end
          RUBY
        end
      end
    end

    context 'with return type redundancy' do
      context 'when both annotation #: and inline #: are present' do
        it 'registers an offense on the inline #: annotation' do
          expect_offense(<<~RUBY)
            #: () -> String
            def method(arg) #: String
                            ^^^^^^^^^ Redundant trailing return type annotation.
            end
          RUBY

          expect_correction(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when both @rbs return and annotation #: are present' do
        it 'registers an offense on the @rbs return annotation' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            #: () -> String
            def method(arg)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when @rbs return, annotation #:, and inline #: are all present' do
        it 'registers offenses on both @rbs return and inline #:' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            #: () -> String
            def method(arg) #: String
                            ^^^^^^^^^ Redundant trailing return type annotation.
            end
          RUBY

          expect_correction(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when only annotation #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when only inline #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when only @rbs return is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end
    end

    context 'with combined parameter and return type redundancy' do
      context 'when # @rbs param:, # @rbs return:, and #: are present' do
        it 'registers offenses on both @rbs annotations' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            ^^^^^^^^^^^^^^^^^ Redundant `@rbs` parameter annotation.
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            #: (Integer) -> String
            def method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            #: (Integer) -> String
            def method(a)
            end
          RUBY
        end
      end
    end

    context 'when no annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is doc_style' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantTypeAnnotation' => {
          'EnforcedStyle' => 'doc_style',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation]
        }
      )
    end

    context 'with parameter type redundancy' do
      context 'when both #: with params and # @rbs param: are present' do
        it 'registers an offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            #: (Integer) -> void
            ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def method(a)
            end
          RUBY
        end
      end

      context 'when both #: with params and # @rbs param: are present on a singleton method' do
        it 'registers an offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            #: (Integer) -> void
            ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def self.method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def self.method(a)
            end
          RUBY
        end
      end

      context 'when multiple # @rbs param: annotations and #: are present' do
        it 'registers an offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            # @rbs b: String
            #: (Integer, String) -> void
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(a, b)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            # @rbs b: String
            def method(a, b)
            end
          RUBY
        end
      end

      context 'when only #: with params is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: (Integer) -> void
            def method(a)
            end
          RUBY
        end
      end

      context 'when only # @rbs param: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs a: Integer
            def method(a) #: void
            end
          RUBY
        end
      end
    end

    context 'with return type redundancy' do
      context 'when both @rbs return and inline #: are present' do
        it 'registers an offense on the inline #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            def method(arg) #: String
                            ^^^^^^^^^ Redundant trailing return type annotation.
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when both @rbs return and annotation #: are present' do
        it 'registers an offense on the annotation #:' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            #: () -> String
            ^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(arg)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when @rbs return, annotation #:, and inline #: are all present' do
        it 'registers offenses on both annotation #: and inline #:' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            #: () -> String
            ^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(arg) #: String
                            ^^^^^^^^^ Redundant trailing return type annotation.
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when only @rbs return is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when only inline #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when only annotation #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end
    end

    context 'with combined parameter and return type redundancy' do
      context 'when # @rbs param:, # @rbs return:, and #: are present' do
        it 'registers offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            # @rbs return: String
            #: (Integer) -> String
            ^^^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            # @rbs return: String
            def method(a)
            end
          RUBY
        end
      end
    end

    context 'when no annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'when EnforcedStyle is doc_style_and_return_annotation' do
    let(:config) do
      RuboCop::Config.new(
        'Style/RbsInline/RedundantTypeAnnotation' => {
          'EnforcedStyle' => 'doc_style_and_return_annotation',
          'SupportedStyles' => %w[method_type_signature doc_style doc_style_and_return_annotation]
        }
      )
    end

    context 'with parameter type redundancy' do
      context 'when both #: with params and # @rbs param: are present' do
        it 'registers an offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            #: (Integer) -> String
            ^^^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def method(a)
            end
          RUBY
        end
      end

      context 'when both #: with params and # @rbs param: are present on a singleton method' do
        it 'registers an offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            #: (Integer) -> String
            ^^^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def self.method(a)
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def self.method(a)
            end
          RUBY
        end
      end

      context 'when only #: with params is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: (Integer) -> String
            def method(a)
            end
          RUBY
        end
      end

      context 'when only # @rbs param: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs a: Integer
            def method(a) #: String
            end
          RUBY
        end
      end
    end

    context 'with return type redundancy' do
      context 'when both @rbs return and inline #: are present' do
        it 'registers an offense on the @rbs return annotation' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            def method(arg) #: String
            end
          RUBY

          expect_correction(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when both annotation #: and inline #: are present' do
        it 'registers an offense on the annotation #:' do
          expect_offense(<<~RUBY)
            #: () -> String
            ^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(arg) #: String
            end
          RUBY

          expect_correction(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when @rbs return, annotation #:, and inline #: are all present' do
        it 'registers offenses on both @rbs return and annotation #:' do
          expect_offense(<<~RUBY)
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            #: () -> String
            ^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(arg) #: String
            end
          RUBY

          expect_correction(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when only @rbs return is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            # @rbs return: String
            def method(arg)
            end
          RUBY
        end
      end

      context 'when only inline #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def method(arg) #: String
            end
          RUBY
        end
      end

      context 'when only annotation #: is present' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            #: () -> String
            def method(arg)
            end
          RUBY
        end
      end
    end

    context 'with combined parameter and return type redundancy' do
      context 'when # @rbs param:, # @rbs return:, and inline #: are present' do
        it 'registers offense on the @rbs return annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            # @rbs return: String
            ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs return` annotation.
            def method(a) #: String
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def method(a) #: String
            end
          RUBY
        end
      end

      context 'when # @rbs param:, #:, and inline #: are present' do
        it 'registers offense on the #: annotation' do
          expect_offense(<<~RUBY)
            # @rbs a: Integer
            #: (Integer) -> String
            ^^^^^^^^^^^^^^^^^^^^^^ Redundant method type signature.
            def method(a) #: String
            end
          RUBY

          expect_correction(<<~RUBY)
            # @rbs a: Integer
            def method(a) #: String
            end
          RUBY
        end
      end
    end

    context 'when no annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def method(a)
          end
        RUBY
      end
    end
  end
end
