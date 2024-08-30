module Dnf
  class BooleanExpression
    attr_reader :expression, :config

    DEFAULT_CONFIG = {
      variable_regex: /\w+/,
      not_symbol: '!',
      and_symbol: '&',
      or_symbol: '|'
    }

    def initialize(expression, custom_config = {})
      @expression = expression
      @config = DEFAULT_CONFIG.merge(custom_config)
    end

    def to_dnf
      expr = parse(expression)
      dnf = convert_to_dnf(expr)
      dnf_to_string(dnf)
    end

    private

    def validate_expression(tokens)
      raise ExpressionSyntaxError, "Expression cannot be empty" if tokens.empty?
      validate_tokens(tokens)
      validate_syntax(tokens)
      validate_parentheses(tokens)
    end

    def validate_tokens(tokens)
      valid_tokens = [
        config[:not_symbol], config[:and_symbol], config[:or_symbol], '(', ')'
      ]
      tokens.each do |token|
        next if valid_tokens.include?(token) || token.match?(/\A#{config[:variable_regex].source}\z/)
        raise ExpressionSyntaxError, "Invalid token: #{token}"
      end
    end

    def validate_syntax(tokens)
      raise ExpressionSyntaxError, "Unexpected start: #{tokens.first}" unless tokens.first.match?(/\A#{config[:variable_regex].source}\z/) || tokens.first == config[:not_symbol] || tokens.first == '('
      tokens.each_cons(2) do |prev, curr|
        case prev
        when config[:variable_regex], ')'
          raise ExpressionSyntaxError, "Unexpected token: #{prev} #{curr}" unless curr == config[:and_symbol] || curr == config[:or_symbol] || curr == ')'
        when config[:not_symbol]
          raise ExpressionSyntaxError, "Unexpected token: #{prev} #{curr}" unless curr.match?(/\A#{config[:variable_regex].source}\z/) || curr == '('
        when config[:and_symbol], config[:or_symbol], '('
          raise ExpressionSyntaxError, "Unexpected token: #{prev} #{curr}" unless curr.match?(/\A#{config[:variable_regex].source}\z/) || curr == config[:not_symbol] || curr == '('
        end
      end
      raise ExpressionSyntaxError, "Unexpected end: #{tokens.last}" unless tokens.last.match?(/\A#{config[:variable_regex].source}\z/) || tokens.last == ')'
    end

    def validate_parentheses(tokens)
      stack = []
      tokens.each do |token|
        if token == '('
          stack.push(token)
        elsif token == ')'
          raise ExpressionSyntaxError, "Mismatched parentheses" if stack.empty?
          stack.pop
        end
      end
      raise ExpressionSyntaxError, "Mismatched parentheses" unless stack.empty?
    end

    def parse(expr)
      tokens = tokenize(expr)
      validate_expression(tokens)
      parse_expression(tokens)
    end

    def tokenize(expr)
      regex = Regexp.union(
        config[:variable_regex],
        config[:not_symbol],
        config[:and_symbol],
        config[:or_symbol],
        /[()]/,
        /\S+/
      )
      expr.scan(regex)
    end

    def parse_expression(tokens)
      parse_or(tokens)
    end

    def parse_or(tokens)
      left = parse_and(tokens)
      while tokens.first == config[:or_symbol]
        tokens.shift
        right = parse_and(tokens)
        left = [:or, left, right]
      end
      left
    end

    def parse_and(tokens)
      left = parse_not(tokens)
      while tokens.first == config[:and_symbol]
        tokens.shift
        right = parse_not(tokens)
        left = [:and, left, right]
      end
      left
    end

    def parse_not(tokens)
      if tokens.first == config[:not_symbol]
        tokens.shift
        expr = parse_primary(tokens)
        [:not, expr]
      else
        parse_primary(tokens)
      end
    end

    def parse_primary(tokens)
      if tokens.first == '('
        tokens.shift
        expr = parse_expression(tokens)
        tokens.shift # skip ')'
        expr
      else
        token = tokens.shift
        [:var, token]
      end
    end

    def convert_to_dnf(expr)
      case expr[0]
      when :var
        expr
      when :not
        convert_not_to_dnf(expr)
      when :and
        left = convert_to_dnf(expr[1])
        right = convert_to_dnf(expr[2])
        distribute_and(left, right)
      when :or
        left = convert_to_dnf(expr[1])
        right = convert_to_dnf(expr[2])
        [:or, left, right]
      end
    end

    def convert_not_to_dnf(expr)
      sub_expr = expr[1]
      case sub_expr[0]
      when :var
        expr
      when :not
        convert_to_dnf(sub_expr[1])
      when :and
        left = convert_not_to_dnf([:not, sub_expr[1]])
        right = convert_not_to_dnf([:not, sub_expr[2]])
        [:or, left, right]
      when :or
        left = convert_not_to_dnf([:not, sub_expr[1]])
        right = convert_not_to_dnf([:not, sub_expr[2]])
        [:and, left, right]
      end
    end

    def distribute_and(left, right)
      if left[0] == :or
        [:or, distribute_and(left[1], right), distribute_and(left[2], right)]
      elsif right[0] == :or
        [:or, distribute_and(left, right[1]), distribute_and(left, right[2])]
      else
        [:and, left, right]
      end
    end

    def dnf_to_string(expr)
      case expr[0]
      when :var
        expr[1]
      when :not
        "#{config[:not_symbol]}#{dnf_to_string(expr[1])}"
      when :and
        "#{dnf_to_string(expr[1])} #{config[:and_symbol]} #{dnf_to_string(expr[2])}"
      when :or
        "#{dnf_to_string(expr[1])} #{config[:or_symbol]} #{dnf_to_string(expr[2])}"
      end
    end
  end
end
