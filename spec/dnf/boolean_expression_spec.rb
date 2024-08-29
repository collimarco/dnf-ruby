require 'spec_helper'
require 'dnf'

RSpec.describe Dnf::BooleanExpression do
  
  it 'allows custom regex for variables' do
    expect(Dnf::BooleanExpression.new('👍 & (b | my-var-c)', variable_regex: /[\w\-👍]+/).to_dnf).to eq('👍 & b | 👍 & my-var-c')
  end
  
  it 'allows custom symbols for boolean operators' do
    expect(Dnf::BooleanExpression.new('¬a ∧ (b ∨ c)', not_symbol: '¬', and_symbol: '∧', or_symbol: '∨').to_dnf).to eq('¬a ∧ b ∨ ¬a ∧ c')
  end
  
  it 'allows multiple symbols for boolean operators' do
    expect(Dnf::BooleanExpression.new('!a && (b || c)', not_symbol: '!', and_symbol: '&&', or_symbol: '||').to_dnf).to eq('!a && b || !a && c')
  end
  
  describe 'validation' do
    it 'raises an exception when the expression is empty' do
      expect {
        Dnf::BooleanExpression.new(' ').to_dnf
      }.to raise_error(Dnf::ExpressionSyntaxError, 'Expression cannot be empty')
    end
    
    it 'raises an exception when a token is invalid' do
      expect {
        Dnf::BooleanExpression.new('a & ### b').to_dnf
      }.to raise_error(Dnf::ExpressionSyntaxError, 'Invalid token: ###')
    end
    
    it 'raises an exception when the syntax is invalid (unexpected token)' do
      expect {
        Dnf::BooleanExpression.new('a & | b').to_dnf
      }.to raise_error(Dnf::ExpressionSyntaxError, 'Unexpected token: & |')
    end
    
    it 'raises an exception when the syntax is invalid (unexpected end)' do
      expect {
        Dnf::BooleanExpression.new('a &').to_dnf
      }.to raise_error(Dnf::ExpressionSyntaxError, 'Unexpected end: &')
    end
    
    it 'raises an exception when the parentheses are mismatched' do
      expect {
        Dnf::BooleanExpression.new('a & ((b | c)').to_dnf
      }.to raise_error(Dnf::ExpressionSyntaxError, 'Mismatched parentheses')
    end
  end
  
  describe '#to_dnf' do
    it 'converts simple variable' do
      expect(Dnf::BooleanExpression.new('a').to_dnf).to eq('a')
    end

    it 'converts negated variable' do
      expect(Dnf::BooleanExpression.new('!a').to_dnf).to eq('!a')
    end

    it 'converts conjunction' do
      expect(Dnf::BooleanExpression.new('a & b').to_dnf).to eq('a & b')
    end

    it 'converts disjunction' do
      expect(Dnf::BooleanExpression.new('a | b').to_dnf).to eq('a | b')
    end
    
    it 'converts parenthesis' do
      expect(Dnf::BooleanExpression.new('(a)').to_dnf).to eq('a')
    end
    
    it 'converts negated parenthesis' do
      expect(Dnf::BooleanExpression.new('!(a)').to_dnf).to eq('!a')
    end

    it 'converts negation of disjunction' do
      expect(Dnf::BooleanExpression.new('!(a | b)').to_dnf).to eq('!a & !b')
    end

    it 'converts negation of conjunction' do
      expect(Dnf::BooleanExpression.new('!(a & b)').to_dnf).to eq('!a | !b')
    end

    it 'converts complex expression' do
      expect(Dnf::BooleanExpression.new('!(a | b) & c').to_dnf).to eq('!a & !b & c')
    end

    it 'converts nested expression' do
      expect(Dnf::BooleanExpression.new('a & (b | c)').to_dnf).to eq('a & b | a & c')
    end

    it 'converts nested expression with negation' do
      expect(Dnf::BooleanExpression.new('!a & (b | c)').to_dnf).to eq('!a & b | !a & c')
    end

    it 'converts multiple nested expressions' do
      expect(Dnf::BooleanExpression.new('(a | b) & (c | d)').to_dnf).to eq('a & c | a & d | b & c | b & d')
    end

    it 'converts multiple negations' do
      expect(Dnf::BooleanExpression.new('!(!a)').to_dnf).to eq('a')
    end

    it 'converts combination of negations and conjunctions' do
      expect(Dnf::BooleanExpression.new('!a & !b').to_dnf).to eq('!a & !b')
    end
    
    it 'converts expressions with many variables in parenthesis' do
      expect(Dnf::BooleanExpression.new('(a | b | c) & d').to_dnf).to eq('a & d | b & d | c & d')
    end
    
    it 'converts expressions with many variables outside parenthesis' do
      expect(Dnf::BooleanExpression.new('(!a | b) & c & d & !e').to_dnf).to eq('!a & c & d & !e | b & c & d & !e')
    end
    
    it 'converts deeply nested expressions' do
      expect(Dnf::BooleanExpression.new('(!(a & b & c) | (!e | d)) & a').to_dnf).to eq('!a & a | !b & a | !c & a | !e & a | d & a')
    end
    
    it 'converts expressions with long variable names' do
      expect(Dnf::BooleanExpression.new('user & (cat | dog)').to_dnf).to eq('user & cat | user & dog')
    end
  end
end
