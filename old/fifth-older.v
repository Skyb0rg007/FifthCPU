`define WIDTH 16
`define DEPTH 4

module fifth(
    input wire clk, reset,

    output wire [12:0] code_addr,
    input  wire [15:0] instruction,

    output wire [15:0] mem_address,
    output wire mem_write_enable,
    input  wire [15:0] mem_data_input,
    output wire [15:0] mem_data_output
);

reg [3:0] dsp, dsp_next, rsp, rsp_next;
reg dstack_write_enable, rstkW;
wire [15:0] rstkD;

reg [15:0] T, T_next;
wire [15:0] N, R;
reg [12:0] pc, pc_next;      
reg reboot = 1;

wire [12:0] pc_plus_1 = pc + 1;
assign mem_address = T_next;
assign code_addr = pc_next;

// The D and R stacks
stack dstack(.clk(clk), .ra(dsp), .rd(N), .we(dstack_write_enable), .wa(dsp_next), .wd(T));
stack rstack(.clk(clk), .ra(rsp), .rd(R), .we(rstkW), .wa(rsp_next), .wd(rstkD));

always @*
begin
    casez (instruction[15:8])
        8'b1??_?????: T_next = { 1'b0, instruction[14:0] };    // literal
        8'b000_?????: T_next = T;                     // jump
        8'b001_?????: T_next = N;                     // conditional jump
        8'b010_?????: T_next = T;                     // call
        8'b011_?0000: T_next = T;                     // ALU operations...
        8'b011_?0001: T_next = N;
        8'b011_?0010: T_next = T + N;
        8'b011_?0011: T_next = T & N;
        8'b011_?0100: T_next = T | N;
        8'b011_?0101: T_next = T ^ N;
        8'b011_?0110: T_next = ~T;
        8'b011_?0111: T_next = {`WIDTH{(N == T)}};
        8'b011_?1000: T_next = {`WIDTH{($signed(N) < $signed(T))}};
        `ifdef NOSHIFTER // `define NOSHIFTER in common.h to cut slice usage in half and shift by 1 only
            8'b011_?1001: T_next = N >> 1;
            8'b011_?1010: T_next = N << 1;
        `else      // otherwise shift by 1-any number of bits
            8'b011_?1001: T_next = N >> T[4:0];
            8'b011_?1010: T_next = N << T[4:0];
        `endif
        8'b011_?1011: T_next = R;
        8'b011_?1100: T_next = mem_data_input;
        // 8'b011_?1101: T_next = io_din;
        8'b011_?1110: T_next = {8'h00, rsp, dsp};
        8'b011_?1111: T_next = {16{N < T}};
        default: T_next = 16'hxxxx;
    endcase
end

wire func_T_N = instruction[6];
wire func_write = instruction[4];
wire func_iow = 0;
// wire func_T_N =   (instruction[6:4] == 1);
// wire func_T_R =   (instruction[6:4] == 2);
// wire func_write = (instruction[6:4] == 3);
// wire func_iow =   (instruction[6:4] == 4);

assign mem_write_enable = !reboot & (instruction[15:13] == 3'b011) & instruction[4];
assign rstkD = (instruction[13] == 1'b0) ? {2'b00, pc_plus_1, 1'b0} : T;

assign mem_data_output = N;


reg [3:0] dspI, rspI;

wire func_T_R = instruction[5];
always @*
begin
casez (instruction[15:13])
    3'b010:   {rstkW, rspI} = {1'b1,      4'b0001};
    3'b011:   {rstkW, rspI} = {func_T_R,  {instruction[3], instruction[3], instruction[3:2]}};
    default:  {rstkW, rspI} = {1'b0,      4'b0000};
endcase
rsp_next = rsp + rspI;

casez (instruction[15:13])
    3'b1??:   {dstack_write_enable, dspI} = {1'b1,      4'b0001};
    3'b001:   {dstack_write_enable, dspI} = {1'b0,      4'b1111};
    3'b011:   {dstack_write_enable, dspI} = {instruction[6],  {instruction[1], instruction[1], instruction[1:0]}};
    default:  {dstack_write_enable, dspI} = {1'b0,      4'b0000};
endcase
dsp_next = dsp + dspI;

casez ({reboot, instruction[15:13], instruction[7], |T})
    6'b1_???_?_?:   pc_next = 0;
    6'b0_000_?_?,
        6'b0_010_?_?,
        6'b0_001_?_0:   pc_next = instruction[12:0];
    6'b0_011_1_?:   pc_next = R[13:1];
    default:        pc_next = pc_plus_1;
endcase
  end

  always @(negedge reset or posedge clk)
  begin
      if (!reset) begin
          // reboot <= 1'b1;
          // { pc, dsp, T, rsp } <= 0;
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









  module stack(
      input wire clk, we,
      input wire [3:0] ra, wa,
      output wire [15:0] rd,
      input wire [15:0] wd
  );

  reg [15:0] store[0:31];

  always @(posedge clk)
      if (we)
          store[wa] <= wd;

      assign rd = store[ra];

      endmodule
