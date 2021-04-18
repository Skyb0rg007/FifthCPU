`default_nettype none
`timescale 1ns/1ps

module fifth_tb;

reg [15:0] ROM[0:1023];
reg clk = 0, reset = 1;
always #5 clk = ~clk;
integer t;

initial
begin
    $readmemh("ROM.hex", ROM);
    $dumpfile("fifth.lxt");
    $dumpvars(0, cpu);

    clk = 1;
    t = 0;
    reset = 0;
    #1;
    reset = 1;
end

always @(posedge clk)
begin
    t <= t + 1;
    if (t == 10)
    begin
        $finish;
    end
end

wire [12:0] code_addr;
wire [15:0] instruction = ROM[code_addr[9:0]];
wire [15:0] mem_address;
wire mem_write_enable;
wire [15:0] mem_data_output;
reg  [15:0] mem_data_input = 16'hxxxx;

fifth cpu(
    .clk(clk),
    .reset(reset),
    .code_addr(code_addr),
    .instruction(instruction),
    .mem_address(mem_address),
    .mem_write_enable(mem_write_enable),
    .mem_data_input(mem_data_input),
    .mem_data_output(mem_data_output)
);

endmodule
