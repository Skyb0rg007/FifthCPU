#! /usr/bin/gforth
\ Cross-compiler for the FIFTH cpu

WARNINGS OFF

\ ROM creation
1024 16 * CONSTANT rom-size
CREATE rom   rom-size ALLOT 
VARIABLE there  rom there !
\ Fill ROM with noops
:NONAME rom-size 0 DO $6000 rom I + w!  16 +LOOP ; EXECUTE

\ Helpers for accessing ROM
: t@  uw@ ; \ Access 16-bit value at address, zero-extending
: t!  w! ;  \ Store 16-bit value at address
: t,  there @ t! 16 there +! ; \ Store 16-bit value, incrementing 'there'
: t.  BASE @ >R HEX S>D <# # # # # #> TYPE R> BASE ! ;
: dump-rom ( -- )
    \ Print ROM in hex, 4 bytes per instruction, 8 instructions per line
    BASE @ HEX
    rom-size 0 DO
        rom I + t@ t. CR
    16 +LOOP
    BASE ! ;

\ Error checking
: assert-address ( addr -- )
    $1fff U> ABORT" Address out of range" ;
: assert-immediate ( n -- )
    $7fff U> ABORT" Immediate out of range" ;
: assert-stack-offset ( n -- )
    -2 2 WITHIN 0= ABORT" Stack offset out of range" ;

\ Compile instructions
: imm ( n -- )
    DUP assert-immediate $8000 OR t, ;
: branch ( addr -- )
    DUP assert-address t, ;
: 0branch ( addr -- )
    DUP assert-address $2000 OR t, ;
: call ( addr -- )
    DUP assert-address $4000 OR t, ;
: alu ( x -- )
    $6000 OR t, ;

%0000 8 LSHIFT CONSTANT T
%0001 8 LSHIFT CONSTANT N
%0010 8 LSHIFT CONSTANT N+T
%0011 8 LSHIFT CONSTANT N&T
%0100 8 LSHIFT CONSTANT N|T
%0101 8 LSHIFT CONSTANT N^T
%0110 8 LSHIFT CONSTANT ~T
%0111 8 LSHIFT CONSTANT N==T
%1000 8 LSHIFT CONSTANT N<T
%1001 8 LSHIFT CONSTANT N>>T
%1010 8 LSHIFT CONSTANT N<<T
%1011 8 LSHIFT CONSTANT R
%1100 8 LSHIFT CONSTANT [T]
%1111 8 LSHIFT CONSTANT Nu<T

: R->PC  1 7 LSHIFT OR ;
: T->N   1 6 LSHIFT OR ;
: T->R   1 5 LSHIFT OR ;
: N->[T] 1 4 LSHIFT OR ;

: d-2 %10 OR ;
: d-1 %11 OR ;
: d+1 %01 OR ;
: r-2 %1000 OR ;
: r-1 %1100 OR ;
: r+1 %0100 OR ;

\ ROM
:NONAME S" ROM.fifth" INCLUDED dump-rom BYE ; EXECUTE
