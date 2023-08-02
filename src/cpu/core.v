`include "../inc/consts.h"
`include "module/memory.v"

module Core(
    input clk,
    input rst
    );

    reg [31:0] pc;
    reg [2:0] stage;
    wire [31:0] mem_data;
    reg [31:0] instruction;
    reg [31:0] addr;
    wire [2:0] debug;
    reg [0:0] load;

    initial begin
        addr <= 31'd0;
        stage <= 2'd0;
        load <= 1'd1;
    end

    Memory memory(
        .load(load),
        .addr(addr),
        .data(mem_data)
    );

    always @(posedge clk) begin
            if(rst) begin
                stage <= `IF;
            end else begin
                if(stage == `WB) begin
                    stage <= `IF;
                end else begin
                    stage <= stage + 1;
                end
            end
        end

    always @(posedge clk) begin
            if(rst) begin
                pc <= 0;
            end else begin
                casez(stage)
                    `IF     :   IntructionFetch();
                    `ID     :   IntructionDecode();
                    `EX     :   pc <= pc;
                    `MEM    :   pc <= pc;
                    `WB     :   pc <= pc;
                endcase
            end
        end

    task IntructionFetch;
        begin
            pc <= pc + 4;
            addr <= pc;
            load <= 1'b0;
        end
    endtask

    task IntructionDecode;
        begin
            load <= 1'b1;
        end
    endtask

endmodule