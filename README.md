
Format:

Immediate: '1' & [15 bit immediate]
Target: "0??" & [13 bit target address]
    "00" -> unconditional jump
    "01" -> conditional jump (jump if TOS is zero, popping TOS)
    "10" -> call
ALU: "011"
    & [1 bit unused]
    & [4 bit opcode]
    & [1 bit (R -> PC)]
    & [3 bits (T -> N, T -> R, I/O write, Memory write)]
    & [2 bit rsp delta]
    & [2 bit dsp delta]

