
module j1_tb;

reg clk = 0, reset = 1;
reg [3:0] read_addr, write_addr;
reg [15:0] read_data, write_data;

always
    #1 clk = !clk;

j1 forth(
    .clk(clk),
    .resetq(reset),
    .read_addr(read_addr),
    .write_addr(write_addr),
    .read_data(read_data),
    .write_data(write_data));

initial
begin
    $dumpfile("j1.vcd");
    $dumpvars(0, j1_tb);
end

endmodule
