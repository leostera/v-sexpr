module sexpr

pub struct Eof {}

pub struct Space {}

pub struct Par_left {}

pub struct Par_right {}

pub struct Char {
	c byte
}

pub type Token = Char | Eof | Par_left | Par_right | Space

pub struct Lexer {
mut:
	tokens []Token
}

pub fn (mut lexer Lexer) read(raw string) {
	for c in raw {
		match c {
			`(` { lexer.tokens << Par_left{} }
			`)` { lexer.tokens << Par_right{} }
			`\n` { lexer.tokens << Space{} }
			` ` { lexer.tokens << Space{} }
			else { lexer.tokens << Char{c} }
		}
	}
	lexer.tokens = lexer.tokens.reverse()
}

pub fn (mut lexer Lexer) next() Token {
	mut result := Token(Eof{})
	if lexer.tokens.len > 0 {
		result = lexer.tokens.pop()
	}
	return result
}

pub fn (lexer Lexer) peek() Token {
	return if lexer.tokens.len > 0 { lexer.tokens.last() } else { Token(Eof{}) }
}

pub struct Atom {
	a string
}

pub struct Cons {
	parts []Sexpr
}

pub type Sexpr = Atom | Cons

pub fn (a Atom) to_string() string {
	return a.a
}

pub fn (c Cons) to_string() string {
	mut str := '('
	mut i := 0
	for p in c.parts {
		str += p.to_string()
		if i < c.parts.len - 1 {
			str += ' '
			i++
		}
	}
	return str + ')'
}

pub fn (sexpr Sexpr) to_string() string {
	return match sexpr {
		Atom { sexpr.to_string() }
		Cons { sexpr.to_string() }
	}
}

pub fn parse(src string) ?[]Sexpr {
	mut lexer := Lexer{
		tokens: []
	}
	lexer.read(src)
	return parse_expr(mut lexer)
}

pub fn parse_expr(mut lexer Lexer) ?[]Sexpr {
	mut exprs := []Sexpr{}
	for {
		token := lexer.peek()
		match token {
			Par_left {
				lexer.next()
				parts := parse_expr(mut lexer) ?
				exprs << Sexpr(Cons{parts})
			}
			Char {
				exprs << (parse_atom(mut lexer) ?)
			}
			Par_right {
				lexer.next()
				break
			}
			Eof {
				break
			}
			else {
				lexer.next()
				continue
			}
		}
	}
	return exprs
}

pub fn parse_atom(mut lexer Lexer) ?Sexpr {
	mut a := ''
	for {
		token := lexer.peek()
		match token {
			Char {
				a += token.c.ascii_str()
				lexer.next()
			}
			Space {
				lexer.next()
				break
			}
			else {
				break
			}
		}
	}
	return Sexpr(Atom{a})
}
