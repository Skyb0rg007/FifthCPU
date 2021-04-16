
module stack(clk, resetq, read_addr, read_data, write_enable, write_addr, write_data);
input wire clk, resetq, write_enable;
input wire [3:0] read_addr, write_addr;
output wire [15:0] read_data;
input wire [15:0] write_data;

reg [15:0] store[0:31];

always @(posedge clk)
    if (write_enable)
        store[write_addr] <= write_data;

assign read_data = store[read_addr];

endmodule


// Main module
module j1(
    clk,
    reset,
    code_addr,
    instruction,
    mem_address,
    mem_write_enable,
    mem_data_output,
    mem_data_input,
    io_write_enable,
    io_data_input
);

// Clock + reset
input wire clk, reset;

// Instructions
output wire [12:0] code_addr;
input wire [15:0] instruction;

// Memory
output wire [15:0] mem_address;
output wire mem_write_enable;
output wire [15:0] mem_data_output;
input  wire [15:0] mem_data_input;

// I/O
output wire io_write_enable;
input  wire [15:0] io_data_input;

// Data and return stacks
reg [3:0] dsp, dsp_next;
reg [3:0] rsp, rsp_next;
reg dsp_write_enable, rsp_write_enable;
wire [15:0] rsp_write_data;

// Registers
reg [15:0] T, T_next;
wire [15:0] N, R;
reg [12:0] pc, pc_next;
wire [12:0] pc_plus_1 = pc + 1;
reg reboot = 1;

assign mem_address = T[15:0];
assign code_addr = pc_next;
assign io_write_enable = (instruction[15:13] == 4'b011) & instruction[4];

stack dstack(
    .clk(clk),
    .resetq(reset),
    .read_addr(dsp),
    .read_data(N),
    .write_enable(dsp_write_enable),
    .write_addr(dsp_next),
    .write_data(T)
);

stack rstack(
    .clk(clk),
    .resetq(reset),
    .read_addr(rsp),
    .read_data(R),
    .write_enable(rsp_write_enable),
    .write_addr(rsp_next),
    .write_data(rsp_write_data)
);

// Calculate T_next
always @*
begin
    casez (instruction[15:8])
        // immed
        8'b1??_?????: T_next = { 1'b0, instruction[14:0] };
        // branch
        8'b000_?????: T_next = T;
        // 0branch
        8'b001_?????: T_next = N;
        // call
        8'b010_?????: T_next = T;
        // alu
        8'b011_00000: T_next = T;
        8'b011_00001: T_next = N;
        8'b011_00010: T_next = N + T;
        8'b011_00011: T_next = N & T;
        8'b011_00100: T_next = N | T;
        8'b011_00101: T_next = N ^ T;
        8'b011_00110: T_next = ~T;
        8'b011_00111: T_next = { 16{N == T} };
        8'b011_01000: T_next = { 16{$signed(N) < $signed(T)} };
        8'b011_01001: T_next = N >> T[4:0];
        8'b011_01010: T_next = N << T[4:0];
        8'b011_01011: T_next = R;
        8'b011_01100: T_next = mem_data_input;
        8'b011_01101: T_next = io_data_input;
        8'b011_01110: T_next = { {8{1'b0}}, rsp, dsp };
        8'b011_01111: T_next = { 16{N < T} };
        default: T_next = 16'bxxxxxxxxxxxxxxxx;
    endcase
end

// Calculate dsp and rsp modifications
always @*
begin
    casez (instruction[15:13])
        3'b1??: begin
            dsp_write_enable = 1'b1;
            dsp_next = dsp + 4'b0001;
        end
        3'b001: begin
            dsp_write_enable = 1'b1;
            dsp_next = dsp + 4'b1111;
        end
        3'b011: begin
            dsp_write_enable = instruction[6]; // T→N
            dsp_next = dsp + { instruction[1], instruction[1], instruction[1:0] }; // dstack
        end
        default: begin
            dsp_write_enable = 1'b0;
            dsp_next = dsp;
        end
    endcase

    casez (instruction[15:13])
        3'b010: begin
            rsp_write_enable = 1'b1;
            rsp_next = rsp + 4'b0001;
        end
        3'b011: begin
            rsp_write_enable = instruction[5]; // T→R
            rsp_next = rsp + { instruction[3], instruction[3], instruction[3:2] }; // rstack
        end
        default: begin
            rsp_write_enable = 1'b0;
            rsp_next = rsp;
        end
    endcase

    casez ({reboot, instruction[15:13], instruction[7] /* R→PC */, |T})
        6'b1_???_?_?: pc_next = 0;
        6'b0_000_?_?,
        6'b0_010_?_?,
        6'b0_001_?_0: pc_next = instruction[12:0];
        6'b0_011_1_?: pc_next = R[13:1];
        default:      pc_next = pc_plus_1;
    endcase
end

// Each clock cycle, set current registers to *_next values
always @(negedge reset or posedge clk)
begin
    if (!reset) begin
        reboot <= 1'b1;
        { pc, dsp, T, rsp } <= 0;
    end else begin
        reboot <= 1'b0;
        pc  <= pc_next;
        dsp <= dsp_next;
        T   <= T_next;
        rsp <= rsp_next;
    end
end

endmodule
