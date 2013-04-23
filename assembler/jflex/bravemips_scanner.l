package grammar;

import java.io.*;
import java_cup.runtime.*;

%%

%public
%type   Symbol
%char

%{
  public Symbol token (int tokenType) {
    System.err.println("Obtain token " + sym.terminal_name(tokenType)
            + " \"" + yytext() + "\"");
    return new Symbol(tokenType, yychar, yychar + yytext().length(), 
                    yytext());
  }
  public Symbol tokenLine (int tokenType) {
    System.err.println("Obtain token " + sym.terminal_name(tokenType)
            + " \"" + yytext() + "\"");
    return new Symbol(tokenType, yyline, yycolumn, yytext());
  }
%}

ident = [A-Za-z][A-Za-z0-9]*
label = [A-za-z][A-Za-z0-9]*[\ \t]*:
space = [\ \t]
newline = \r|\n|\r\n
comment = #.*
register = \$[rR]0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31
hex = \b0[xX][0-9a-fA-F]+\b
binary = \b0[bB][01]+\b
decimal = \b\d+\b

%%

"add"       { return token(sym.ADD); }
"addi"      { return token(sym.ADDI); }
"sll"       { return token(sym.SLL); }
"jmp"       { return token(sym.JMP); }
"jmpr"      { return token(sym.JMPR); }
{newline}   { return token(sym.NEWLINE); }
{space}     { }
{comment}   { }
{decimal}   { return token(sym.DECIMAL); }
{hex}       { return token(sym.HEX); }
{binary}    { return token(sym.BINARY); }
{ident}     { return token(sym.IDENTIFIER); }
{label}     { return tokenLine(sym.LABEL); }
{register}  { return token(sym.REGISTER); }

.           { return token(sym.error); }
<<EOF>>     { return token(sym.EOF); }