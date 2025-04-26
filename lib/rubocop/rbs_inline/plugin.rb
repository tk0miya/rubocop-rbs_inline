# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module RbsInline
    # A plugin that integrates RuboCop RBS Inline with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-rbs_inline',
          version: RuboCop::RbsInline::VERSION,
          homepage: 'https://github.com/tk0miya/rubocop-rbs_inline',
          description: 'rubocop-rbs_inline is a RuboCop extension that checks for RBS::Inline annotation comments ' \
                       'in Ruby code.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../../') # steep:ignore

        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: project_root.join('config', 'default.yml'))
      end
    end
  end
end
