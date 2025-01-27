#[allow(dead_code)]
#[derive(Clone, PartialEq, Debug)]
pub enum Token {
    Program, // program
    Begin, End, // begin end
    Semicolon, // ;
    Lparen, Rparen, // ( )
    Assign, // :=
    Cop(String), // == != < > =< >=
    Eop(String), // + -
    Top(String), // * /
    If, Then, Else, // if then else
    While, Do, // while do
    Read, Write, // read write
    Id(String), Integer(i32), // identifiers and integers
}

// nossa árvore de sintaxe
#[derive(Clone, PartialEq, Debug)]
pub enum AstNode {
    Program {id: Box<AstNode>, statement: Box<AstNode>},
    Semicolon { statement1: Box<AstNode>, statement2: Box<AstNode> },
    Assign { id: Box<AstNode>, expression: Box<AstNode> },
    If { comparison: Box<AstNode>, statement1: Box<AstNode>, statement2: Box<AstNode> },
    While { comparison: Box<AstNode>, statement: Box<AstNode> },
    Read { id: Box<AstNode> },
    Write { expression: Box<AstNode> },
    Comparison { operator: Box<AstNode>, expression1: Box<AstNode>, expression2: Box<AstNode> },
    Expression { operator: Box<AstNode>, expression1: Box<AstNode>, expression2: Box<AstNode> },
    Cop(String), Op(String), Id(String), Integer(i32),
}

// função tostring básica
impl ToString for AstNode {
    fn to_string(&self) -> String {
        match self {
            AstNode::Program { id, statement } => format!("prog({} {})", id.to_string(), statement.to_string()),
            AstNode::Semicolon { statement1, statement2 } => format!(";({} {})", statement1.to_string(), statement2.to_string()),
            AstNode::Assign { id, expression } => format!("assign({} {})", id.to_string(), expression.to_string()),
            AstNode::If { comparison, statement1, statement2 } => format!("if({} {} {})", comparison.to_string(), statement1.to_string(), statement2.to_string()),
            AstNode::While { comparison, statement } => format!("while({} {})", comparison.to_string(), statement.to_string()),
            AstNode::Read { id } => format!("read({})", id.to_string()),
            AstNode::Write { expression } => format!("write({})", expression.to_string()),
            AstNode::Comparison { operator, expression1, expression2 } => format!("{}({} {})", operator.to_string(), expression1.to_string(), expression2.to_string()),
            AstNode::Expression { operator, expression1, expression2 } => format!("{}({} {})", operator.to_string(), expression1.to_string(), expression2.to_string()),
            AstNode::Cop(op) => format!("{}", op),
            AstNode::Op(op) => format!("{}", op),
            AstNode::Id(id) => format!("{}", id),
            AstNode::Integer(i) => format!("{}", i),
        }
    }
}

type Tokens = [Token];

// função parse geral, começa usando o parse_program.
pub fn parse(tokens: &Tokens) -> Result<Box<AstNode>, String> {
    let (result, _) = parse_program(tokens)?;
    Ok(result)
}

// program <id> ; <stat> end
pub fn parse_program(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    match tokens {
        [Token::Program, Token::Id(id), Token::Semicolon, r1 @ ..] => { // program <id> ;
            let (stat, r2) = parse_statement(r1)?; // <stat>
            let [Token::End, rest @ ..] = r2 else { return Err("Expected 'end' after statement.".to_string()); }; // end
            Ok((Box::new(AstNode::Program { id: Box::new(AstNode::Id(id.to_string())), statement: stat }), rest)) // Return
        },
        _ => Err("Expected syntax: program <id> ; <stat> end".to_string()),
    }
}

// { <STAT> ; } <STAT>
pub fn parse_statement_sequence(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    let (stat1, r1) = parse_statement(tokens)?;

    match r1 {
        // caso 1: tem ; então tem que continuar recursivamente
        [Token::Semicolon, r2 @ ..] => {
            let (stat2, rest) = parse_statement_sequence(r2)?;
            Ok((Box::new(AstNode::Semicolon { statement1: stat1, statement2: stat2 }), rest))
        }

        // caso 2: só retorna o statement
        _ => {
            Ok((stat1, r1))
        }
    }
}

pub fn parse_statement(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    match tokens {
        // BEGIN { <STAT> ; } <STAT> END (;)
        [Token::Begin, r1 @ ..] => {
            let (stat, r2) = parse_statement_sequence(r1)?; // { <STAT> ; } <STAT>
            let [Token::End, rest @ ..] = r2 else { return Err("Expected 'end'.".to_string()) }; // END
            Ok((stat, rest))
        }
        
        // <ID> := <EXPR> (assign)
        [Token::Id(id), Token::Assign, r1 @ ..] => { // <id> :=
            let (expr, rest) = parse_expression(r1)?; // <expr>
            Ok((Box::new(AstNode::Assign { id: Box::new(AstNode::Id(id.to_string())), expression: expr }), rest)) // return
        }
        
        // IF <COMP> THEN <STAT> ELSE <STAT> (if)
        [Token::If, r1 @ ..] => { // if
            let (comp , r2) = parse_comparison(r1)?; // <comp>
            let [Token::Then, r3 @ ..] = r2 else { return Err("Expected 'then' after comparison.".to_string()); }; // then
            let (stat1, r4) = parse_statement(r3)?; // <stat>
            let [Token::Else, r5 @ ..] = r4 else { return Err("Expected 'else' after first statement.".to_string()); }; // else
            let (stat2, rest) = parse_statement(r5)?; // <stat>
            Ok((Box::new(AstNode::If { comparison: comp, statement1: stat1, statement2: stat2 }), rest)) // return
        }

        // WHILE <COMP> DO <STAT> (while)
        [Token::While, r1 @ ..] => { // while
            let (comp, r2) = parse_comparison(r1)?; // <comp>
            let [Token::Do, r3 @ ..] = r2 else { return Err("Expected 'do' after comparison".to_string()); }; // do
            let (stat, rest) = parse_statement(r3)?; // <stat>
            Ok((Box::new(AstNode::While { comparison: comp, statement: stat }), rest)) // return
        }

        // READ <ID> (read)
        [Token::Read, Token::Id(id), rest @ ..] => { // read <id>
            Ok((Box::new(AstNode::Read { id: Box::new(AstNode::Id(id.to_string())) }), rest)) // return
        }

        // WRITE <EXPR> (write)
        [Token::Write, r1 @ ..] => { // write
            let (expr, rest) = parse_expression(r1)?; // <expr>
            Ok((Box::new(AstNode::Write { expression: expr }), rest)) // return
        }
        
        _ => {Err("Invalid statement".to_string())}
    }
}

// Não faz sentido, seguindo as linguagens de input e output, ter mais de uma comparação, porque sequer existe algo como um "and",
// e não existe um caso na linguagem de output para múltiplas comparações. Aqui eu implemento uma comparação só.
// <expr> <cop> <expr>
pub fn parse_comparison(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    let (expr1, r1) = parse_expression(tokens)?; // <expr>
    let [Token::Cop(op), r2 @ ..] = r1 else { return Err("Expected COP after Expression.".to_string()) }; // <cop>
    let (expr2, rest) = parse_expression(r2)?; // <expr>
    Ok((Box::new(AstNode::Comparison { operator: Box::new(AstNode::Cop(op.to_string())), expression1: expr1, expression2: expr2 }), rest)) // return
}

// {<term> <eop>} <term>
pub fn parse_expression(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    let (term1, r1) = parse_term(tokens)?; // pega o primeiro termo

    match r1 {
        // Caso 1: tem um operador, tem que continuar o parse
        [Token::Eop(op), r2 @ ..] => {
            let (term2, rest) = parse_expression(r2)?;
            Ok((Box::new(AstNode::Expression { operator: Box::new(AstNode::Op(op.to_string())), expression1: term1, expression2: term2 }), rest))
        }

        // Caso 2: Não tem operador, a expressão é só o primeiro termo.
        _ => { Ok((term1, r1)) }
    }
}

// {<fact> <top>} <fact>
pub fn parse_term(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    let (factor1, r1) = parse_factor(tokens)?; // pega o primeiro fator

    match r1 {
        // Caso 1: tem um operador, tem que continuar o parse
        [Token::Top(op), r2 @ ..] => {
            let (factor2, rest) = parse_term(r2)?;
            Ok((Box::new(AstNode::Expression { operator: Box::new(AstNode::Op(op.to_string())), expression1: factor1, expression2: factor2 }), rest))
        }

        // Caso 2: Não tem operador, o termo é só o primeiro fator.
        _ => { Ok((factor1, r1)) }
    }
}

pub fn parse_factor(tokens: &Tokens) -> Result<(Box<AstNode>, &Tokens), String> {
    match tokens {
        [Token::Integer(int), rest @ ..] => Ok((Box::new(AstNode::Integer(*int)), rest)),
        [Token::Id(id), rest @ ..] => Ok((Box::new(AstNode::Id(id.to_string())), rest)),
        [Token::Lparen, r1 @ ..] => { // (
            let (expr, r2) = parse_expression(r1)?; // <expr>
            let [Token::Rparen, rest @ ..] = r2 else { return Err("Expected ).".to_string()); }; // )
            Ok((expr, rest))
        },
        _ => Err("Expected ID, Integer, or Expression.".to_string()),
    }
}