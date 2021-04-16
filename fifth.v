
module fifth(
    // Standard inputs
    input  wire clk, reset,
    // Instruction + instruction address
    output wire [12:0] code_addr,
    input  wire [15:0] instruction,
    // Memory access
    output wire [15:0] mem_address,
    output wire mem_write_enable,
    input  wire [15:0] mem_data_input,
    output wire [15:0] mem_data_output
);

reg [3:0] dsp, dsp_next, rsp, rsp_next;
reg dstack_write_enable, rstack_write_enable;
wire [15:0] rstack_write_data;

reg [15:0] T, T_next;
wire [15:0] N, R;
reg [12:0] pc, pc_next;
reg reboot = 1;

fifth_stack dstack(
    .clk(clk),
    .write_enable(dstack_write_enable),
    .read_addr(dsp),
    .read_data(N),
    .write_addr(dsp_next),
    .write_data(T)
);

fifth_stack rstack(
    .clk(clk),
    .write_enable(rstack_write_enable),
    .read_addr(rsp),
    .read_data(R),
    .write_addr(rsp_next),
    .write_data(rstack_write_data)
);

assign code_addr = pc_next;
assign mem_address = T_next;
assign mem_write_enable = !reboot && (instruction[15:13] == 3'b011) && instruction[4]; // N->[T]
assign rstack_write_data = instruction[13] == 1'b0 ?  { 2'b11, pc + 12'b1, 1'b0 } : T;

always @*
begin
    casez (instruction[15:8])
        8'b1??_?????: T_next = { 1'b0, instruction[14:0] }; // immed
        8'b000_?????: T_next = T; // branch
        8'b001_?????: T_next = N; // 0branch
        8'b010_?????: T_next = T; // call
        8'b011_00000: T_next = T;
        8'b011_00001: T_next = N;
        8'b011_00010: begin
            $display("**** N(%x) + T(%x) = %x", N, T, N + T);
            T_next = N + T;
        end
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
        8'b011_01101: T_next = T/* TODO */;
        8'b011_01110: T_next = { {8{1'b0}}, rsp, dsp };
        8'b011_01111: T_next = { 16{N < T} };
        default: T_next = 16'bxxxxxxxxxxxxxxxx;
    endcase
end

reg [3:0] dsp_delta, rsp_delta;
always @*
begin
    casez (instruction[15:13])
        3'b1??:  {dstack_write_enable, dsp_delta} = { 1'b1, 4'b0001 };
        3'b001:  {dstack_write_enable, dsp_delta} = { 1'b0, 4'b1111 };
        3'b011:
        begin
            {dstack_write_enable, dsp_delta} = {instruction[6], {instruction[1], instruction[1], instruction[1:0]}};
            $display("instruction: %x", instruction);
            $display("instruction[6]: %x", instruction[6]);
            $display("dstack_write_enable: %x", dstack_write_enable);
        end
        default: {dstack_write_enable, dsp_delta} = { 1'b0, 4'b0000 };
        // 3'b1??: begin
        //     dstack_write_enable = 1'b1;
        //     dsp_next = dsp + 4'b0001;
        // end
        // 3'b001: begin
        //     dstack_write_enable = 1'b0;
        //     dsp_next = dsp + 4'b1111;
        // end
        // 3'b011: begin
        //     dstack_write_enable = instruction[6]; // T→N
        //     dsp_next = dsp + { instruction[1], instruction[1], instruction[1:0] }; // dstack
        // end
        // default: begin
        //     dstack_write_enable = 1'b0;
        //     dsp_next = dsp;
        // end
    endcase
    dsp_next = dsp + dsp_delta;

    casez (instruction[15:13])
        3'b010:  {rstack_write_enable, rsp_delta} = { 1'b1, 4'b0001 };
        3'b011:  {rstack_write_enable, rsp_delta} = { instruction[5], {instruction[3], instruction[3], instruction[3:2]} };
        default: {rstack_write_enable, rsp_delta} = { 1'b0, 4'b0000 };
        // 3'b010: begin
        //     rstack_write_enable = 1'b1;
        //     rsp_next = rsp + 4'b0001;
        // end
        // 3'b011: begin
        //     rstack_write_enable = instruction[5]; // T→R
        //     rsp_next = rsp + { instruction[3], instruction[3], instruction[3:2] }; // rstack
        // end
        // default: begin
        //     rstack_write_enable = 1'b0;
        //     rsp_next = rsp;
        // end
    endcase
    rsp_next = rsp + rsp_delta;

    casez ({reboot, instruction[15:13], instruction[7] /* R→PC */, |T})
        6'b1_???_?_?: pc_next = 0;
        6'b0_000_?_?,
        6'b0_010_?_?,
        6'b0_001_?_0: pc_next = instruction[12:0];
        6'b0_011_1_?: pc_next = R[13:1];
        default:      pc_next = pc + 1;
    endcase
end

always @(negedge reset or posedge clk)
begin
    if (!reset) begin
        $display("Resetting...");
        reboot <= 1'b1;
        pc  <= 0;
        dsp <= 0;
        T   <= 0;
        rsp <= 0;
    end else begin
        $display("Tick");
        reboot <= 1'b0;
        pc  <= pc_next;
        dsp <= dsp_next;
        T   <= T_next;
        rsp <= rsp_next;
    end
end

endmodule

module fifth_stack(
    input  wire clk, write_enable,
    input  wire [3:0] read_addr, write_addr,
    output wire [15:0] read_data,
    input  wire [15:0] write_data
);

reg [15:0] store[0:31];

always @(posedge clk)
begin
    if (write_enable)
        store[write_addr] <= write_data;
end

assign read_data = store[read_addr];

endmodule
