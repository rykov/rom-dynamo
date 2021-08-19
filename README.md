[gem]: https://rubygems.org/gems/rom-dynamo
[aws]: https://github.com/aws/aws-sdk-core-ruby

# Rom::Dynamo

[![Gem Version](https://badge.fury.io/rb/rom-dynamo.svg)][gem]
[![Build Status](https://github.com/rykov/rom-dynamo/actions/workflows/specs.yml/badge.svg)](https://github.com/rykov/rom-dynamo/actions/workflows/specs.yml)

AWS DynamoDB support for [Ruby Object Mapper](https://github.com/rom-rb/rom).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rom-dynamo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rom-dynamo

## Usage

ROM-Dynamo uses [aws-sdk-core][aws] library, so you will need to initialize that first:

    Aws.config.merge!({
      credentials:   Aws::Credentials.new(AWS_ACCESS, AWS_SECRET),
      region:        'us-east-1'
    })

To connect, use the following URL to specify the AWS region and table name prefix.  In this case, accessing `photos` will map to the table `table-name-prefix-photos`:

    dynamo://region/table-name-prefix-/

So a sample setup will be:

    rom = ROM.setup(:dynamo, 'dynamo://us-east-1/development_app_/') do
      relation(:photos) do
        # This will call GetItem API directly
        def by_id(id)
          restrict(id: id)
        end

        # This will first query a Global Secondary Index
        def all_for_user(id)
          index_restrict('user-to-id', user_id: id)
        end
      end

      commands(:photos) do
        define(:create) { result(:one) }
        define(:delete) { result(:one) }
      end
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/rykov/rom-dynamo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
