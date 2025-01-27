defmodule Parser do
  def into_str(token) do
    case token do
      %{token: :program, id: id, statement: statement} -> "prog(#{into_str(id)} #{into_str(statement)})"
      %{token: :semicolon, statement1: statement1, statement2: statement2} -> ";(#{into_str(statement1)} #{into_str(statement2)})"
      %{token: :assign, id: id, expression: expression} -> "assign(#{into_str(id)} #{into_str(expression)})"
      %{token: :if, comparison: comparison, statement1: statement1, statement2: statement2} -> "if(#{into_str(comparison)} #{into_str(statement1)} #{into_str(statement2)})"
      %{token: :while, comparison: comparison, statement: statement} -> "while(#{into_str(comparison)} #{into_str(statement)})"
      %{token: :read, id: id} -> "read(#{into_str(id)})"
      %{token: :write, expression: expression} -> "write(#{into_str(expression)})"
      %{token: :comparison, operator: operator, expression1: expression1, expression2: expression2} -> "#{into_str(operator)}(#{into_str(expression1)} #{into_str(expression2)})"
      %{token: :expression, operator: operator, expression1: expression1, expression2: expression2} -> "#{into_str(operator)}(#{into_str(expression1)} #{into_str(expression2)})"
      %{token: :cop, value: value} -> value
      %{token: :op, value: value} -> value
      %{token: :id, value: value} -> value
      %{token: :integer, value: value} -> to_string(value)
    end
  end

  # a gente basicamente só vai fazendo chamadas recursivas nos tokens, pegando um por um.
  # a gente "consome" os que encaixam na sintaxe e vai encaixando o resto com chamadas recursivas no restante dos tokens.
  def parse(tokens) do
    case parse_program(tokens) do
      {:ok, result, _} -> {:ok, result}
      {:error, error} -> {:error, error}
    end
  end

  # program <id> ; <stat> end
  def parse_program(tokens) do
    case tokens do
      [%{token: :program}, %{token: :id, value: id}, %{token: :semicolon} | rest] -> # program <id> ;
        case parse_statement(rest) do # chamada recursiva pra parse no <stat>
          {:ok, statement, rest} ->
            case rest do # checks if it has 'end' after <stat>
              [%{token: :end} | rest] -> {:ok, %{token: :program, id: %{token: :id, value: id}, statement: statement}, rest} # end
              _ -> {:error, "Expected 'end' after statement."}
            end
          {:error, error} -> {:error, error} # o erro foi no parse_statement
        end
      _ -> {:error, "Expected syntax: program <id> ; <stat> end"}
    end
  end


  # dá parse em sequências de { <stat> ; } <stat>.
  # é necessário pq fica difícil e bagunçado de fazer isso com o begin e o end dentro
  # da função principal.
  def parse_statement_sequence(tokens) do
    case parse_statement(tokens) do # <stat>
      {:ok, statement1, r1} ->
        case r1 do
          [%{token: :semicolon} | r2] -> # se tem ; é pq tem que continuar recursivamente
            case parse_statement_sequence(r2) do
              {:ok, statement2, rest} ->
                {:ok, %{token: :semicolon, statement1: statement1, statement2: statement2}, rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, statement1, r1} # se não, só retorna o stat
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_statement(tokens) do
    case tokens do
      [%{token: :begin} | r1] -> # begin
        case parse_statement_sequence(r1) do # dá um parse recursivo esperando { <stat> ; } <stat>
          {:ok, statement, r2} ->
            case r2 do
              [%{token: :end} | rest] -> {:ok, statement, rest} # checa se termina com um token end
              _ -> {:error, "Expected 'end'."}
            end
          {:error, error} -> {:error, error}
        end

      [%{token: :id, value: id}, %{token: :assign} | r1] -> # <id> :=
        case parse_expression(r1) do # <expr>
          {:ok, expression, rest} -> {:ok, %{token: :assign, id: %{token: :id, value: id}, expression: expression}, rest}
          {:error, error} -> {:error, error}
        end

      [%{token: :if} | r1] -> # if
        case parse_comparison(r1) do # <comp>
          {:ok, comparison, r2} ->
            case r2 do
              [%{token: :then} | r3] -> # <then>
                case parse_statement(r3) do # <stat>
                  {:ok, statement1, r4} ->
                    case r4 do
                      [%{token: :else} | r5] -> # <else>
                        case parse_statement(r5) do # <stat>
                          {:ok, statement2, rest} -> {:ok, %{token: :if, comparison: comparison, statement1: statement1, statement2: statement2}, rest}
                          {:error, error} -> {:error, error}
                        end
                      _ -> {:error, "Expected 'else' after first statement."}
                    end # fim else
                  {:error, error} -> {:error, error}
                end # fim stat
              _ -> {:error, "Expected 'then' after comparison."}
            end # fim then
          {:error, error} -> {:error, error}
        end # fim comp

      [%{token: :while} | rest] -> # while
        case parse_comparison(rest) do # <comp>
          {:ok, comparison, rest} ->
            case rest do
              [%{token: :do} | rest] -> # do
                case parse_statement(rest) do # <stat>
                  {:ok, statement, rest} -> {:ok, %{token: :while, comparison: comparison, statement: statement}, rest}
                  {:error, error} -> {:error, error}
                end
              _ -> {:error, "Expected 'do' after comparison."}
            end
          {:error, error} -> {:error, error}
        end

      [%{token: :read}, %{token: :id, value: id} | rest] -> {:ok, %{token: :read, id: %{token: :id, value: id}}, rest} # read id

      [%{token: :write} | rest] -> # write
        case parse_expression(rest) do # <expr>
          {:ok, expression, rest} -> {:ok, %{token: :write, expression: expression}, rest}
          {:error, error} -> {:error, error}
        end

      _ -> {:error, "Invalid statement."}
    end
  end

  # Não faz sentido, seguindo as linguagens de input e output, ter mais de uma comparação, porque sequer existe algo como um "and",
  # e não existe um caso na linguagem de output para múltiplas comparações. Aqui eu implemento uma comparação só.
  # <expr> <cop> <expr>
  def parse_comparison(tokens) do
    case parse_expression(tokens) do # <expr>
      {:ok, expression1, rest} ->
        case rest do
          [%{token: :cop, value: op} | rest] -> # <cop>
            case parse_expression(rest) do # <expr>
              {:ok, expression2, rest} -> {:ok, %{token: :comparison, operator: %{token: :cop, value: op}, expression1: expression1, expression2: expression2}, rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:error, "Expected COP after Expression."}
        end
      {:error, error} -> {:error, error}
    end
  end

  # {<term> <eop>} <term>
  def parse_expression(tokens) do
    case parse_term(tokens) do # pega o primeiro termo
      {:ok, term1, rest} ->
        case rest do
          [%{token: :eop, value: op} | rest] -> # se tiver operador, tem mais termos, continua o parse
            case parse_expression(rest) do
              {:ok, term2, rest} -> {:ok, %{token: :expression, operator: %{token: :op, value: op}, expression1: term1, expression2: term2}, rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, term1, rest} # se não, a expressão é só  primeiro termo
        end
      {:error, error} -> {:error, error}
    end
  end

  # {<fact> <top>} <fact>
  def parse_term(tokens) do
    case parse_factor(tokens) do # pega o primeiro fator
      {:ok, factor1, rest} ->
        case rest do
          [%{token: :top, value: op} | rest] -> # se tiver operador, tem mais fatores, continua o parse
            case parse_term(rest) do
              {:ok, factor2, rest} -> {:ok, %{token: :expression, operator: %{token: :op, value: op}, expression1: factor1, expression2: factor2}, rest}
              {:error, error} -> {:error, error}
            end
          _ -> {:ok, factor1, rest} # se não, o termo é só o primeiro fator
        end
      {:error, error} -> {:error, error}
    end
  end

  def parse_factor(tokens) do
    case tokens do
      # int
      [%{token: :integer, value: value} | rest] -> {:ok, %{token: :integer, value: value}, rest}
      # id
      [%{token: :id, value: value} | rest] -> {:ok, %{token: :id, value: value}, rest}
      # ( <expr> )
      [%{token: :lparen} | rest] -> # tira o primeiro parentese do jogo
        case parse_expression(rest) do # parse na expressao
          {:ok, expression, rest} ->
            case rest do
              [%{token: :rparen} | rest] -> {:ok, expression, rest} # checa se tem o parentese que fecha
              _ -> {:error, "Expected )."} # se não, vrau.
            end
          {:error, error} -> {:error, error}
        end
      _ -> {:error, "Expected ID, Integer, or Expression."}
    end
  end
end

defmodule Main do
  def main() do
    # Programa de exemplo que usa todos os tokens
    tokens = [
      %{token: :program}, %{token: :id, value: "all_tokens"}, %{token: :semicolon}, # program all_tokens ;
        %{token: :begin}, # begin
          # stat 1    -->    x := 10;
          %{token: :id, value: "x"}, %{token: :assign}, %{token: :integer, value: 10}, %{token: :semicolon},

          # stat 2    -->    if x > 5 then write x else write 0;
          %{token: :if}, %{token: :id, value: "x"}, %{token: :cop, value: ">"}, %{token: :integer, value: 5}, %{token: :then},
            %{token: :write}, %{token: :id, value: "x"},
          %{token: :else},
            %{token: :write}, %{token: :integer, value: 0},
          %{token: :semicolon},

          # stat 3    -->    while x < 10 do x := x + 1;
          %{token: :while}, %{token: :id, value: "x"}, %{token: :cop, value: "<"}, %{token: :integer, value: 10}, %{token: :do},
            %{token: :id, value: "x"}, %{token: :assign}, %{token: :id, value: "x"}, %{token: :eop, value: "+"}, %{token: :integer, value: 1},
          %{token: :semicolon},

          # stat 4    -->    read y;
          %{token: :read}, %{token: :id, value: "y"}, %{token: :semicolon},

          # stat 5    -->    write (x * y)
          %{token: :write}, %{token: :lparen}, %{token: :id, value: "x"}, %{token: :top, value: "*"}, %{token: :id, value: "y"}, %{token: :rparen},
        %{token: :end}, # end
      %{token: :end} # end
    ]

    case Parser.parse(tokens) do
      {:ok, ast} -> IO.inspect(Parser.into_str(ast))
      {:error, error} -> IO.puts("Error: #{error}")
    end
  end
end

Main.main()
