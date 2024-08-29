# DNF

Convert any boolean expression to disjunctive normal form (DNF).

## Installation

```ruby
gem 'dnf'
```

## Usage

Basic usage:

```ruby
expression = "(!a | !b) & c"
boolean_expression = Dnf::BooleanExpression.new(expression)
boolean_expression.to_dnf # => "!a & c | !b & c"
```

Config:

```ruby
Dnf::BooleanExpression.new(expression, {
  variable_regex: /\w+/,
  not_symbol: '!',
  and_symbol: '&',
  or_symbol: '|'
})
```

## License

The gem is available as open source under the terms of the MIT License.
