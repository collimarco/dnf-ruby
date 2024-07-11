module Dnf
  class BooleanExpression
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def to_dnf
      expr = parse(expression)
      dnf = convert_to_dnf(expr)
      dnf_to_string(dnf)
    end

    private

    def parse(expr)
      tokens = tokenize(expr)
      parse_expression(tokens)
    end

    def tokenize(expr)
      expr.scan(/\w+|[&|!()]/)
    end

    def parse_expression(tokens)
      parse_or(tokens)
    end

    def parse_or(tokens)
      left = parse_and(tokens)
      while tokens.first == '|'
        tokens.shift
        right = parse_and(tokens)
        left = [:or, left, right]
      end
      left
    end

    def parse_and(tokens)
      left = parse_not(tokens)
      while tokens.first == '&'
        tokens.shift
        right = parse_not(tokens)
        left = [:and, left, right]
      end
      left
    end

    def parse_not(tokens)
      if tokens.first == '!'
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
        "!#{dnf_to_string(expr[1])}"
      when :and
        "#{dnf_to_string(expr[1])} & #{dnf_to_string(expr[2])}"
      when :or
        "#{dnf_to_string(expr[1])} | #{dnf_to_string(expr[2])}"
      end
    end
  end
end
