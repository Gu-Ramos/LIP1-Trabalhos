defmodule Token do
  defstruct [:type, :value]
end

defmodule AstNode do
  defstruct [:type, :id, :statement, :comparison, :expression, :operator, :expression1, :expression2, :statement1, :statement2, :value]

  def program(id, statement), do: %AstNode{type: :program, id: id, statement: statement}
  def semicolon(statement1, statement2), do: %AstNode{type: :semicolon, statement1: statement1, statement2: statement2}
  def assign(id, expression), do: %AstNode{type: :assign, id: id, expression: expression}
  def if_(comparison, statement1, statement2), do: %AstNode{type: :if, comparison: comparison, statement1: statement1, statement2: statement2}
  def while_(comparison, statement), do: %AstNode{type: :while, comparison: comparison, statement: statement}
  def read(id), do: %AstNode{type: :read, id: id}
  def write(expression), do: %AstNode{type: :write, expression: expression}
  def comparison(operator, expression1, expression2), do: %AstNode{type: :comparison, operator: operator, expression1: expression1, expression2: expression2}
  def expression(operator, expression1, expression2), do: %AstNode{type: :expression, operator: operator, expression1: expression1, expression2: expression2}
  def cop(value), do: %AstNode{type: :cop, value: value}
  def op(value), do: %AstNode{type: :op, value: value}
  def id(value), do: %AstNode{type: :id, value: value}
  def integer(value), do: %AstNode{type: :integer, value: value}
end

defmodule Parser do
  def parse(tokens) do
    case parse_program(tokens) do
      {:ok, result, _} -> {:ok, result}
      {:error, error} -> {:error, error}
    end
  end

  def parse_program(tokens) do
    case tokens do
      [%Token{type: :program}, %Token{type: :id, value: id}, %Token{type: :semicolon} | rest] ->
        case parse_statement(rest) do
          {:ok, statement, rest} ->
            case rest do
              [%Token{type: :end} | rest] ->
                {:ok, %AstNode{type: :program, id: id, statement: statement}, rest}
              _ -> {:error, "Expected 'end' after statement."}
            end
          {:error, error} -> {:error, error}
        end
      _ -> {:error, "Expected syntax: program <id> ; <stat> end"}
    end
  end

  def parse_statement_sequence(tokens) do
    case parse_statement(tokens) do
      {:ok, statement1, rest} ->
        case rest do
          [%Token{type: :semicolon} | rest] ->
            case parse_statement_sequence(rest) do
              {:ok, statement2, rest} ->
                {:ok, AstNode.semicolon(statement1, statement2), rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, statement1, rest}
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_statement(tokens) do
    case tokens do
      [%Token{type: :begin} | rest] ->
        case parse_statement_sequence(rest) do
          {:ok, statement, rest} ->
            case rest do
              [%Token{type: :end} | rest] ->
                {:ok, statement, rest}
              _ -> {:error, "Expected 'end'."}
            end
          {:error, error} -> {:error, error}
        end
      [%Token{type: :id, value: id}, %Token{type: :assign} | rest] ->
        case parse_expression(rest) do
          {:ok, expression, rest} ->
            {:ok, AstNode.assign(AstNode.id(id), expression), rest}
          {:error, error} -> {:error, error}
        end
      [%Token{type: :if} | rest] ->
        case parse_comparison(rest) do
          {:ok, comparison, rest} ->
            case rest do
              [%Token{type: :then} | rest] ->
                case parse_statement(rest) do
                  {:ok, statement1, rest} ->
                    case rest do
                      [%Token{type: :else} | rest] ->
                        case parse_statement(rest) do
                          {:ok, statement2, rest} ->
                            {:ok, AstNode.if_(comparison, statement1, statement2), rest}
                          {:error, error} -> {:error, error}
                        end
                      _ -> {:error, "Expected 'else' after first statement."}
                    end
                  {:error, error} -> {:error, error}
                end
              _ -> {:error, "Expected 'then' after comparison."}
            end
          {:error, error} -> {:error, error}
        end
      [%Token{type: :while} | rest] ->
        case parse_comparison(rest) do
          {:ok, comparison, rest} ->
            case rest do
              [%Token{type: :do} | rest] ->
                case parse_statement(rest) do
                  {:ok, statement, rest} ->
                    {:ok, AstNode.while_(comparison, statement), rest}
                  {:error, error} -> {:error, error}
                end
              _ -> {:error, "Expected 'do' after comparison."}
            end
          {:error, error} -> {:error, error}
        end
      [%Token{type: :read}, %Token{type: :id, value: id} | rest] ->
        {:ok, AstNode.read(AstNode.id(id)), rest}
      [%Token{type: :write} | rest] ->
        case parse_expression(rest) do
          {:ok, expression, rest} ->
            {:ok, AstNode.write(expression), rest}
          {:error, error} -> {:error, error}
        end
      _ -> {:error, "Invalid statement."}
    end
  end

  def parse_comparison(tokens) do
    case parse_expression(tokens) do
      {:ok, expression1, rest} ->
        case rest do
          [%Token{type: :cop, value: op} | rest] ->
            case parse_expression(rest) do
              {:ok, expression2, rest} ->
                {:ok, AstNode.comparison(AstNode.cop(op), expression1, expression2), rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:error, "Expected COP after Expression."}
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_expression(tokens) do
    case parse_term(tokens) do
      {:ok, term1, rest} ->
        case rest do
          [%Token{type: :eop, value: op} | rest] ->
            case parse_expression(rest) do
              {:ok, term2, rest} ->
                {:ok, AstNode.expression(AstNode.op(op), term1, term2), rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, term1, rest}
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_term(tokens) do
    case parse_factor(tokens) do
      {:ok, factor1, rest} ->
        case rest do
          [%Token{type: :top, value: op} | rest] ->
            case parse_term(rest) do
              {:ok, factor2, rest} ->
                {:ok, AstNode.expression(AstNode.op(op), factor1, factor2), rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, factor1, rest}
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_factor(tokens) do
    case tokens do
      [%Token{type: :integer, value: value} | rest] ->
        {:ok, AstNode.integer(value), rest}
      [%Token{type: :id, value: value} | rest] ->
        {:ok, AstNode.id(value), rest}
      [%Token{type: :lparen} | rest] ->
        case parse_expression(rest) do
          {:ok, expression, rest} ->
            case rest do
              [%Token{type: :rparen} | rest] ->
                {:ok, expression, rest}
              _ -> {:error, "Expected )."}
            end
          {:error, error} -> {:error, error}
        end
      _ -> {:error, "Expected ID, Integer, or Expression."}
    end
  end
end
