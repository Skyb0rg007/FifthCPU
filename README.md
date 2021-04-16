
Instruction Format:

            ┏━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    immed   ┃ 1 ┃ 15-bit immediate                                          ┃
            ┣━━━┻━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    branch  ┃ 000 ┃ 13-bit address                                          ┃
            ┣━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    0branch ┃ 001 ┃ 13-bit address                                          ┃
            ┣━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
    call    ┃ 010 ┃ 13-bit address                                          ┃
            ┣━━━━━╋━━━━━━━━━━━━┳━━━━┳━━━┳━━━┳━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━┫
    alu     ┃ 011 ┃5-bit opcode┃R→PC┃T→N┃T→R┃N→[T]┃2-bit rstack┃2-bit dstack┃
            ┗━━━━━┻━━━━━━━━━━━━┻━━━━┻━━━┻━━━┻━━━━━┻━━━━━━━━━━━━┻━━━━━━━━━━━━┛

    R→PC:   Set the program counter to the top of the return stack
    T→N:    Set the second data stack element to the top of the stack
    T→R:    Set the top of the return stack to the top of the data stack
    N→[T]:  Set the memory at the address given by T to the second stack element
    rstack: Signed 2-bits indicating the total return stack delta
    dstack: Signed 2-bits indicating the total data stack delta

Opcodes:

    0000: T := T
    0001: T := N
    0010: T := N + T
    0011: T := N & T
    0100: T := N | T
    0101: T := N ^ T
    0110: T := ~T
    0111: T := N == T
    1000: T := N < T
    1001: T := N >> T
    1010: T := N << T
    1011: T := R
    1100: T := [T]
    1101: T := 
    1110: T := (rsp << 4) | dsp
    1111: T := N u< T

Example FORTH definitions:

- +: `011 0 0010 0 0 0 00 11`
    - ALU, opcode `T := N+T`, dstack `-1`
- drop: `011 0 0001 0 0 0 00 11`
    - ALU, opcode `T := N`, dstack `-1`
- dup: `011 0 0000 1 0 0 00 01`
    - ALU, opcode `T := T`, `T→N`, dstack `+1`
- tuck !: `011 0 0000 0 0 1 00 11`
    - ALU, opcode `T := T`, `N→*T`, dstack `-1`

