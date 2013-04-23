To get the output of the JFlex (as a java file):
- create the lexer file
- issue the following command
    jflex -d <directory> -v --time <inputfiles>
    e.g.: jflex -d D:\Study\DTU\1\02211\BraveMIPS\assembler\jflex -v --time D:\Study\DTU\1\02211\BraveMIPS\assembler\jflex\bravemips_scanner.l
- wait for the output