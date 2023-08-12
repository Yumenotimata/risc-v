`include "consts.h"
`include "regfile.v"
`include "memory.v"
`include "decoder.v"

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

    //Program Memory
    wire [31:0] memory_out_addr,memory_out_data,memory_write_addr,memory_write_data;
    reg memory_write_enable;
    Memory memory(
        .clk(clk),
        .memory_out_addr(memory_out_addr),
        .memory_out_data(memory_out_data),
        .memory_write_addr(memory_write_addr),
        .memory_write_data(memory_write_data),
        .memory_write_enable(memory_write_enable)
    );

    reg decoder_valid;
    Decoder decoder(
        .decoder_valid(decoder_valid),
        .decode_instruction(memory_out_data)
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

    // always @(posedge clk) begin
        // casez(stage)
            // `IF     :   
        // endcase
    // end

endmodule