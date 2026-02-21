# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::RbsInline::RedundantAnnotationWithSkip, :config do
  context 'with @rbs skip annotation' do
    context 'when method type signature is present' do
      it 'registers an offense on the method type signature' do
        expect_offense(<<~RUBY)
          # @rbs skip
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when doc-style method type annotation is present' do
      it 'registers an offense on the doc-style method type annotation' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when param annotation is present' do
      it 'registers an offense on the param annotation' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when multiple param annotations are present' do
      it 'registers an offense on each param annotation' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          # @rbs b: String
          ^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a, b)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a, b)
          end
        RUBY
      end
    end

    context 'when return annotation is present' do
      it 'registers an offense on the return annotation' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when trailing return type is present' do
      it 'registers an offense on the trailing return type' do
        expect_offense(<<~RUBY)
          # @rbs skip
          def method(a) #: void
                        ^^^^^^^ Redundant trailing return type annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when both method type signature and param annotations are present' do
      it 'registers offenses on both' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when block type annotation is present' do
      it 'registers an offense on the block annotation' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs &block: () -> void
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(&block)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(&block)
          end
        RUBY
      end
    end

    context 'when on a singleton method' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          # @rbs skip
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature. `@rbs skip` and `@rbs override` skip RBS generation.
          def self.method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def self.method(a)
          end
        RUBY
      end
    end

    context 'when no other annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'with @rbs override annotation' do
    context 'when method type signature is present' do
      it 'registers an offense on the method type signature' do
        expect_offense(<<~RUBY)
          # @rbs override
          #: (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^ Redundant method type signature. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end

    context 'when doc-style method type annotation is present' do
      it 'registers an offense on the doc-style method type annotation' do
        expect_offense(<<~RUBY)
          # @rbs override
          # @rbs (Integer) -> void
          ^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end

    context 'when param annotation is present' do
      it 'registers an offense on the param annotation' do
        expect_offense(<<~RUBY)
          # @rbs override
          # @rbs a: Integer
          ^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end

    context 'when return annotation is present' do
      it 'registers an offense on the return annotation' do
        expect_offense(<<~RUBY)
          # @rbs override
          # @rbs return: String
          ^^^^^^^^^^^^^^^^^^^^^ Redundant `@rbs` annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end

    context 'when trailing return type is present' do
      it 'registers an offense on the trailing return type' do
        expect_offense(<<~RUBY)
          # @rbs override
          def method(a) #: void
                        ^^^^^^^ Redundant trailing return type annotation. `@rbs skip` and `@rbs override` skip RBS generation.
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end

    context 'when no other annotations are present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'with duplicate @rbs skip annotations' do
    it 'registers an offense on the second skip' do
      expect_offense(<<~RUBY)
        # @rbs skip
        # @rbs skip
        ^^^^^^^^^^^ Duplicate `@rbs skip` annotation.
        def method(a)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs skip
        def method(a)
        end
      RUBY
    end
  end

  context 'with duplicate @rbs override annotations' do
    it 'registers an offense on the second override' do
      expect_offense(<<~RUBY)
        # @rbs override
        # @rbs override
        ^^^^^^^^^^^^^^^ Duplicate `@rbs override` annotation.
        def method(a)
        end
      RUBY

      expect_correction(<<~RUBY)
        # @rbs override
        def method(a)
        end
      RUBY
    end
  end

  context 'with both @rbs skip and @rbs override' do
    context 'when skip comes first' do
      it 'registers an offense on the override' do
        expect_offense(<<~RUBY)
          # @rbs skip
          # @rbs override
          ^^^^^^^^^^^^^^^ `@rbs skip` and `@rbs override` cannot both be specified.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs skip
          def method(a)
          end
        RUBY
      end
    end

    context 'when override comes first' do
      it 'registers an offense on the skip' do
        expect_offense(<<~RUBY)
          # @rbs override
          # @rbs skip
          ^^^^^^^^^^^ `@rbs skip` and `@rbs override` cannot both be specified.
          def method(a)
          end
        RUBY

        expect_correction(<<~RUBY)
          # @rbs override
          def method(a)
          end
        RUBY
      end
    end
  end

  context 'without @rbs skip or @rbs override' do
    context 'when method type signature is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          #: (Integer) -> void
          def method(a)
          end
        RUBY
      end
    end

    context 'when param annotation is present' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @rbs a: Integer
          def method(a)
          end
        RUBY
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
