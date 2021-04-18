#! /usr/bin/gforth
\ Cross-compiler for the FIFTH cpu

\ GForth warns on redefinition
warnings off

VARIABLE num-instructions  0 num-instructions !

: instr. ( instr -- )
    DUP $ffff U> ABORT" Instruction out of range"
    BASE @ >R
    HEX S>D <# # # # # #> TYPE SPACE
    1 num-instructions +!
    num-instructions @ $f AND 0= IF
        CR
    THEN
    R> BASE ! ;
: noop-pad ( -- )
    1024 num-instructions @ ?DO
        $6000 instr.
    LOOP ;

\ Error checking
: assert-address ( addr -- )
    $1fff U> ABORT" Address out of range" ;
: assert-immediate ( n -- )
    $7fff U> ABORT" Immediate out of range" ;
: assert-stack-offset ( n -- )
    -2 2 WITHIN 0= ABORT" Stack offset out of range" ;

\ Compile instructions
: imm ( n -- )
    DUP assert-immediate $8000 OR instr. ;
: branch ( addr -- )
    DUP assert-address instr. ;
: 0branch ( addr -- )
    DUP assert-address $2000 OR instr. ;
: call ( addr -- )
    DUP assert-address $4000 OR instr. ;
: alu ( x -- )
    $6000 OR instr. ;

\ 12-8: ALU opcode
%00000 $8 LSHIFT CONSTANT T
%00001 $8 LSHIFT CONSTANT N
%00010 $8 LSHIFT CONSTANT N+T
%00011 $8 LSHIFT CONSTANT N&T
%00100 $8 LSHIFT CONSTANT N|T
%00101 $8 LSHIFT CONSTANT N^T
%00110 $8 LSHIFT CONSTANT ~T
%00111 $8 LSHIFT CONSTANT N==T
%01000 $8 LSHIFT CONSTANT N<T
%01001 $8 LSHIFT CONSTANT N>>T
%01010 $8 LSHIFT CONSTANT N<<T
%01011 $8 LSHIFT CONSTANT R
%01100 $8 LSHIFT CONSTANT [T]
%01111 $8 LSHIFT CONSTANT Nu<T

\ 7-4: bits determining special things
: R->PC  %1  $7 LSHIFT OR ;
: T->N   %1  $6 LSHIFT OR ;
: T->R   %1  $5 LSHIFT OR ;
: N->[T] %1  $4 LSHIFT OR ;

\ 3-2: rstack delta
: r-2    %10 $2 LSHIFT OR ;
: r-1    %11 $2 LSHIFT OR ;
: r+1    %01 $2 LSHIFT OR ;

\ 1-0: dstack delta
: d-2    %10 $0 LSHIFT OR ;
: d-1    %11 $0 LSHIFT OR ;
: d+1    %01 $0 LSHIFT OR ;

\ Compile the ROM
next-arg INCLUDED
noop-pad
BYE
