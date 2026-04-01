[gem]: https://rubygems.org/gems/rom-dynamo
[actions]: https://github.com/rykov/rom-dynamo/actions/workflows/specs.yml
[docs]: https://rubydoc.info/gems/rom-dynamo

# rom-dynamo

[![Gem Version](https://badge.fury.io/rb/rom-dynamo.svg)][gem]
[![Build Status](https://github.com/rykov/rom-dynamo/actions/workflows/specs.yml/badge.svg)][actions]

AWS DynamoDB adapter for [ROM](https://rom-rb.org/) (Ruby Object Mapper).

## Installation

```ruby
gem 'rom-dynamo'
```

## Usage

ROM-Dynamo uses the [aws-sdk-dynamodb](https://github.com/aws/aws-sdk-ruby) library. Configure AWS credentials before connecting:

```ruby
Aws.config.merge!(
  credentials: Aws::Credentials.new(AWS_ACCESS, AWS_SECRET),
  region: 'us-east-1'
)
```

Connect using a URI that specifies the AWS region and an optional table name prefix:

    dynamo://REGION/TABLE_PREFIX/

For example, with the URI below, accessing `photos` maps to the DynamoDB table `myapp_photos` in `us-east-1` region:

    dynamo://us-east-1/myapp_/

### Relations

```ruby
rom = ROM.container(:dynamo, 'dynamo://us-east-1/myapp_/') do |config|
  config.relation(:photos) do
    schema(infer: true)

    def by_id(id)
      restrict(id: id)
    end

    def all_for_user(user_id)
      index_restrict('user-to-id', user_id: user_id)
    end
  end
end
```

### Repository

```ruby
class PhotosRepo < ROM::Repository[:photos]
  commands :create, update: :by_id, delete: :by_id

  def by_id(id)
    photos.restrict(id: id).one
  end
end

repo = PhotosRepo.new(rom)
repo.create({ id: 1, user_id: 42, url: 'https://example.com/photo.jpg' })
repo.by_id(1)
```

## Compatibility

- Ruby >= 2.4 (MRI and JRuby)
- ROM >= 5.0, < 6.0
- aws-sdk-dynamodb ~> 1.0

## Links

- [API Documentation][docs]
- [ROM Learn](https://rom-rb.org/learn/)

## License

MIT
