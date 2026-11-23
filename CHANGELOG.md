# Changelog

## 0.17.0

- Replaced legacy DynamoDB parameters with expressions
- Serialize Time and DateTime on create and delete
- Updated README with modern examples
- Added DynamoDB Local for testing
- Added and applied Rubocop

## 0.16.0

- Support for Ruby 4.0 and ActiveSupport 8.x
- Fixed Relation#each_page auto-map and auto-struct
- Expose #each_page to allow pagination control

## 0.15.0

- Added #offset to Dataset and Relation
- Added GitHub Actions workflow for specs

## 0.14.0

- Updated dependencies

## 0.13.1

- Added support for `limit` and `reversed` query options
- Generalize from :conditions to :query in Dataset

## 0.12.5

- Switch Dataset to Dry::Initializer

## 0.12.1

- Batch get index results by page

## 0.12.0

- Support for ROM 4.x and ROM 5.x

## 0.11.0

- Support for ROM 4.0.x

## 0.10.0

- Upgrade to AWS SDK v3 (aws-sdk-dynamodb)

## 0.9.0

- Fix return values for commands

## 0.8.0

- ROM 3.0 support

## 0.7.0

- ROM 2.0 support

## 0.6.0

- Add #batch_restrict for batch get by keys
- JRuby 9.0.5.0 autoload compatibility fix

## 0.5.0

- Upgrade to ROM 1.0.0

## 0.4.0

- Updates for ROM 0.9.x compatibility

## 0.3.4

- Compatibility fix for aws-sdk-core 2.1.x

## 0.3.2

- Add support for DateTime serializing

## 0.3.1

- Fix Update command to iterate by key

## 0.3.0

- Add support for :update command

## 0.2.0

- Update to ROM 0.7.0

## 0.1.4

- Initial release
