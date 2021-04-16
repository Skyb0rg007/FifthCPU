`timescale 1ns/1ps

module fifth_tb();

reg [15:0] ROM[0:1023];
reg [15:0] RAM[0:1023];
reg clk = 0, reset = 1;
always #5 clk = ~clk;
integer t;

initial
begin
    $readmemh("ROM.hex", ROM);

    // $monitor("%3d code_addr = %x",   $time, code_addr);
    // $monitor("%3d mem_address = %x", $time, mem_address);
    // $monitor("%3d instruction = %x", $time, instruction);
    // $monitor("%3d reset = %x",       $time, reset);
    $dumpfile("fifth.vcd");
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
wire [15:0] instruction;
assign instruction = ROM[code_addr];

wire [15:0] mem_address;
wire mem_write_enable;
wire [15:0] mem_data_output;
reg [15:0] mem_data_input;

// Data input: 
// 0x0000 - 0x3fff: ROM
// 0x4000 - 0x7fff: RAM
// 0x8000 - 0xffff: N/A
always @*
begin
    if (mem_address[15:11] == 4'b0000)
        mem_data_input = RAM[mem_address[14:0]];
    else if (mem_address[15:11] == 4'b0001)
        mem_data_input = RAM[mem_address[10:0]];
    else
        mem_data_input = 16'hxxxx;
end

always @(posedge clk)
begin
    if (mem_write_enable)
        RAM[mem_address] = mem_data_output;
end

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

//j1 cpu(
//    .clk(clk),
//    .resetq(reset),
//    .code_addr(code_addr),
//    .insn(instruction),
//    .mem_addr(mem_address),
//    .mem_wr(mem_write_enable),
//    .mem_din(mem_data_input),
//    .dout(mem_data_output)
//);

endmodule
