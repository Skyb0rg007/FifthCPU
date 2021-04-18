`default_nettype none

module fifth(
    // Standard inputs
    input wire clk, reset,
    // Instruction + instruction address
    output wire [12:0] code_addr,   // Address of the instruction
    input  wire [15:0] instruction, // Instruction to run. Format in README
    // Memory access
    output wire [15:0] mem_address,    // 16-bit address
    output wire mem_write_enable,      // Whether `mem_data_output` should be written to `mem_address`
    input  wire [15:0] mem_data_input, // The data at `mem_address`
    output wire [15:0] mem_data_output // The data to be written
);

// Stack info
reg [3:0] dsp, dsp_next, rsp, rsp_next;       // The index into the data+return stacks
reg dstack_write_enable, rstack_write_enable; // Whether anything is written when the index is incremented
wire [15:0] rstack_write_data;                // What gets written into the return stack when its index is incremented

// Registers
reg [15:0] T, T_next;   // Top of the data stack
wire [15:0] N, R;       // Second data stack element, top return stack element
reg [12:0] pc, pc_next; // Program counter
reg reboot = 1;         // When set, resets pc to 0

// The data stack
fifth_stack dstack(
    .clk(clk),
    .write_enable(dstack_write_enable),
    .read_addr(dsp),
    .read_data(N),         // N is wired to the top of the real data stack
    .write_addr(dsp_next),
    .write_data(T)         // What's written when the stack is incremented
);

// The return stack
fifth_stack rstack(
    .clk(clk),
    .write_enable(rstack_write_enable),
    .read_addr(rsp),
    .read_data(R),                 // R is wired to the top of the return stack
    .write_addr(rsp_next),
    .write_data(rstack_write_data)
);

// Calculate T_next from its previous value
always @*
begin
    casez (instruction[15:8])
        // IMMED
        8'b1??_?????: T_next = { 1'b0, instruction[14:0] };
        // BRANCH
        8'b000_?????: T_next = T;
        // 0BRANCH
        8'b001_?????: T_next = N;
        // CALL
        8'b010_?????: T_next = T;
        // ALU (TODO: More operations?)
        8'b011_00000: T_next = T;
        8'b011_00001: T_next = N;
        8'b011_00010: T_next = N + T;
        8'b011_00011: T_next = N & T;
        8'b011_00100: T_next = N | T;
        8'b011_00101: T_next = N ^ T;
        8'b011_00110: T_next = ~T;
        8'b011_00111: T_next = { 16{N == T} };
        8'b011_01000: T_next = { 16{$signed(N) < $signed(T)} };
        /* TODO: Barrel shifter cost analysis - maybe only support shift by 1 */
        8'b011_01001: T_next = N >> T[4:0];
        8'b011_01010: T_next = N << T[4:0];
        8'b011_01011: T_next = R;
        8'b011_01100: T_next = mem_data_input;
        8'b011_01101: T_next = T/* TODO */;
        8'b011_01110: T_next = { {8{1'b0}}, rsp, dsp };
        8'b011_01111: T_next = { 16{N < T} };
        default:      T_next = 16'hxxxx;
    endcase
end

// Decoding instructions

// BRANCH and 0BRANCH, top of rstack is set to pc+1
// For ALU operations, top of rstack is set to T when T→R bit is set
assign rstack_write_data = instruction[13] == 1'b0 ?  { 2'b00, pc + 12'b1, 1'b0 } : T;
wire RtoPC  = instruction[7]; // R→PC
wire TtoN   = instruction[6]; // T→N
wire TtoR   = instruction[5]; // T→R
wire NtoMem = instruction[4]; // N→[T]
wire [3:0] dstack_delta = { instruction[1], instruction[1], instruction[1:0] };
wire [3:0] rstack_delta = { instruction[3], instruction[3], instruction[3:2] };

// Output wiring
assign code_addr = pc_next;  // Self-explainatory
assign mem_address = T_next; // Top of stack is used for fetch opcode (FORTH @)
assign mem_data_output = N;  // Next on stack is used for store opcode (FORTH !)
assign mem_write_enable = !reboot && (instruction[15:13] == 3'b011) && NtoMem; // Check for `N->[T]` bit

// Calculate stack and pc modifications
always @*
begin
    // Data stack
    casez (instruction[15:13])
        3'b1??: begin // IMMED
            dstack_write_enable = 1;
            dsp_next = dsp + 1;
        end
        3'b001: begin // 0BRANCH
            dstack_write_enable = 0;
            dsp_next = dsp - 1;
        end
        3'b011: begin // ALU
            dstack_write_enable = TtoN;
            dsp_next = dsp + dstack_delta;
        end
        default: begin // BRANCH/CALL
            dstack_write_enable = 0;
            dsp_next = dsp;
        end
    endcase

    // Return stack
    casez (instruction[15:13])
        3'b010: begin // CALL
            rstack_write_enable = 1;
            rsp_next = rsp + 1;
        end
        3'b011: begin // ALU
            rstack_write_enable = TtoR;
            rsp_next = rsp + rstack_delta;
        end
        default: begin // BRANCH/0BRANCH
            rstack_write_enable = 0;
            rsp_next = rsp;
        end
    endcase

    // PC
    casez ({reboot, instruction[15:13], RtoPC /* R→PC */, |T})
        6'b1_???_?_?: pc_next = 0;                 // IMMED
        6'b0_000_?_?: pc_next = instruction[12:0]; // BRANCH
        6'b0_001_?_0: pc_next = instruction[12:0]; // 0BRANCH (T == 0)
        6'b0_010_?_?: pc_next = instruction[12:0]; // CALL
        6'b0_011_1_?: pc_next = R[13:1];           // ALU (R→PC set)
        default:      pc_next = pc + 1;            // otherwise
    endcase
end

// Move the *_next registers into the current registers
always @(negedge reset or posedge clk)
begin
    if (!reset) begin
        reboot <= 1'b1;
        pc  <= 0;
        dsp <= 0;
        T   <= 0;
        rsp <= 0;
    end else begin
        $display("Instruction: %x", instruction);
        $display("  dstack_write_enable: %d", dstack_write_enable);
        reboot <= 1'b0;
        pc  <= pc_next;
        dsp <= dsp_next;
        T   <= T_next;
        rsp <= rsp_next;
    end
end

endmodule

// Handles data + return stack logic

/* verilator lint_off DECLFILENAME */
module fifth_stack(
    input  wire clk, write_enable,
    input  wire [3:0] read_addr, write_addr,
    output wire [15:0] read_data,
    input  wire [15:0] write_data
);

reg [15:0] store[0:15];

always @(posedge clk)
begin
    if (write_enable)
        store[write_addr] <= write_data;
end

assign read_data = store[read_addr];

endmodule
/* verilator lint_on DECLFILENAME */
