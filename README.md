# DNF

Convert any boolean expression to disjunctive normal form (DNF).

## Installation

```ruby
gem 'dnf'
```

## Usage

```ruby
expression = "(!a | !b) & c"
boolean_expression = Dnf::BooleanExpression.new(expression)
boolean_expression.to_dnf # => "!a & c | !b & c"
```

## License

The gem is available as open source under the terms of the MIT License.
