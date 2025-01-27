// Dupla:
// Maria Luiza Felipe Carolino - 552655
// Gustavo Andrade Ramos - 558279
mod parser;
use parser::*;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Programa de exemplo que usa todos os tokens
    let tokens = [
        Token::Program, Token::Id("all_tokens".to_string()), Token::Semicolon, // program all_tokens ;
            Token::Begin, // begin
                // stat 1    -->    x := 10;
                Token::Id("x".to_string()), Token::Assign, Token::Integer(10), Token::Semicolon, // x := 10 ;
                
                // stat 2    -->    if x > 5 then write x else write 0;
                Token::If, Token::Id("x".to_string()), Token::Cop(">".to_string()), Token::Integer(5), Token::Then, // if x > 5 then
                    Token::Write, Token::Id("x".to_string()), // write x
                Token::Else, // else
                    Token::Write, Token::Integer(0), // write 0
                Token::Semicolon, // ;
                
                // stat 3    -->    while x < 10 do x := x + 1;
                Token::While, Token::Id("x".to_string()), Token::Cop("<".to_string()), Token::Integer(10), Token::Do, // while x < 10 do
                    Token::Id("x".to_string()), Token::Assign, Token::Id("x".to_string()), Token::Eop("+".to_string()), Token::Integer(1), // x := x + 1
                Token::Semicolon, // ;

                // stat 4    -->    read y;
                Token::Read, Token::Id("y".to_string()), Token::Semicolon, // read y ;
                
                // stat 5    -->    write (x * y)
                Token::Write, Token::Lparen, Token::Id("x".to_string()), Token::Top("*".to_string()), Token::Id("y".to_string()), Token::Rparen, // write (x * y)        
            Token::End, // end
        Token::End // end
    ];

    let result = parse(&tokens)?;
    println!("{}", result.to_string());

    Ok(())
}
