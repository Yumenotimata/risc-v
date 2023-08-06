`include "consts.h"
`include "regfile.v"

module Core(
    input clk,
    input rst
);

    reg [2:0] stage;

    //Register
    wire [4:0] reg_read_addr,reg_write_addr;
    wire [31:0] reg_write_data,reg_read_data;
    Regfile regfile(
        .clk(clk),
        .reg_read_addr(reg_read_addr),
        .reg_write_addr(reg_write_addr),
        .reg_read_data(reg_read_data),
        .reg_write_data(reg_write_data)
    );

    initial begin
        stage <= `IF;
    end

    always @(posedge clk) begin
        if((stage == `WB) || rst) begin
            stage <= `IF;
        end
        else begin
            stage <= stage + 1; 
        end
    end

endmodule