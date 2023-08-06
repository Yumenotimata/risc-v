module Regfile(
    input clk,
    input [4:0] reg_read_addr,reg_write_addr,
    input [31:0] reg_write_data,
    output [31:0] reg_read_data
);

    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for(i=0;i<32;i++) begin
            regs[i] <= i;
        end
    end

    always @(posedge clk) begin
        regs[reg_write_addr] <= reg_write_data;
    end

    assign reg_read_data = regs[reg_read_addr];

endmodule