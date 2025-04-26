# rubocop-rbs_inline

rubocop-rbs_inline is a RuboCop extension that checks for [RBS::Inline](https://github.com/soutaro/rbs-inline) annotation comments in Ruby code.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add rubocop-rbs_inline
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install rubocop-rbs_inline
```

Add the following to your `.rubocop.yml`:

```
plugins:
  - rubocop-rbs_inline
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and add Git tag named `vX.Y.Z` and push it to the GitHub.  Then GitHub Actions will be release the package to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rubocop-rbs_inline. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tk0miya/rubocop-rbs_inline/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubocop-rbs_inline project's codebases and issue trackers is expected to follow the [code of conduct](https://github.com/tk0miya/rubocop-rbs_inline/blob/main/CODE_OF_CONDUCT.md).
