`include "../inc/consts.h"
`include "../inc/instruction.h"
`include "module/memory.v"

module Core(
    input clk,
    input rst
    );
    
    //internal bus
    reg [31:0] pc;
    reg [2:0] stage;
    reg [31:0] inst;

    //Memory 
    reg [31:0] w_data;
    reg [0:0] wen;
    reg [0:0] d_load;
    wire [31:0] mem_data;
    wire [31:0] d_mem_data;
    reg [0:0] load;
    reg [31:0] addr;
    reg [31:0] d_addr;

    //Register
    reg [31:0] register [31:0];

    //Decoder
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;
    reg [12:0] imm_i;
    reg [12:0] imm_s;
    reg [31:0] imm_s_sext;
    reg [31:0] imm_i_sext;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [31:0] rd;

    //ALU
    reg [31:0] alu_out;

    integer i;
    initial begin
        inst <= 32'd0;
        addr <= 32'd0;
        stage <= 2'd0;
        load <= 1'd1;
        d_load <= 1'd1;
        w_data <= 32'd0;
        rs1_addr <= 5'd0;
        rs2_addr <= 5'd0;
        rd_addr <= 5'd0;
        wen <= 1'd1;
        for(i=0;i<32;i++) begin
            register[i] <= i;
        end
    end

    Memory memory(
        .load(load),
        .d_load(d_load),
        .addr(addr),
        .d_addr(d_addr),
        .data(mem_data),
        .d_data(d_mem_data),
        .w_data(w_data),
        .wen(wen)
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
                    `EX     :   Excution();
                    `MEM    :   MemoryAccess();
                    `WB     :   WriteBack();
                endcase
            end
        end

    task IntructionFetch;
        begin
            pc <= pc + 4;
            addr <= pc;
            //load memory enable
            load <= 1'b0;
        end
    endtask

    task IntructionDecode;
        begin
            inst <= mem_data;
            //load memory disable
            load <= 1'b1;
            //for debug
            rs1_addr <= mem_data[19:15];
            rs2_addr <= mem_data[24:20];
            rd_addr <= mem_data[11:7];
            imm_i <= mem_data[31:20];
            imm_s <= {{mem_data[31:25]},{mem_data[11:7]}};
            //sign extension
            //{} -> materialization?
            imm_i_sext <= {{20{mem_data[31]}},mem_data[31:20]};
            imm_s_sext <= {{20{mem_data[31]}},{mem_data[31:25],mem_data[11:7]}};
            //direct load
            rs1 <= register[mem_data[19:15]];
            rs2 <= register[mem_data[24:20]];
            rd <=  register[mem_data[11:7]];
        end
    endtask

    task Excution;
    begin
        casez(inst)
            `LW     :   alu_out <= {rs1 + imm_i_sext};
            `SW     :   alu_out <= {rs1 + imm_s_sext};
            `ADD    :   alu_out <= {rs1 + rs2};
            `SUB    :   alu_out <= {rs1 - rs2};
            `ADDI   :   alu_out <= {rs1 + imm_i_sext};
            `AND    :   alu_out <= {rs1 & rs2};
            `OR     :   alu_out <= {rs1 | rs2};
            `XOR    :   alu_out <= {rs1 ^ rs2};
            `ANDI   :   alu_out <= {rs1 & imm_i_sext};
            `ORI    :   alu_out <= {rs1 | imm_i_sext};
            `XORI   :   alu_out <= {rs1 ^ imm_i_sext};
        endcase
    end
    endtask

    task MemoryAccess;
    begin
        casez(inst)
            `LW     :   
                begin 
                    d_addr <= alu_out;
                    d_load <= 1'b0;
                end
            `SW     :
                begin
                    d_addr <= alu_out;
                    wen <= 1'b0;
                    w_data <= rs2;
                end
        endcase
    end
    endtask

    task WriteBack;
    begin
        d_load <= 1'b1;
        wen <= 1'b1;
        casez(inst)
            `LW     :   register[rd_addr] <= d_mem_data;
            `ADD    :   register[rd_addr] <= alu_out;
            `SUB    :   register[rd_addr] <= alu_out;
            `ADDI   :   register[rd_addr] <= alu_out;
            `AND    :   register[rd_addr] <= alu_out;
            `OR     :   register[rd_addr] <= alu_out;
            `XOR    :   register[rd_addr] <= alu_out;
            `ANDI   :   register[rd_addr] <= alu_out;
            `ORI    :   register[rd_addr] <= alu_out;
            `XORI   :   register[rd_addr] <= alu_out;
        endcase
    end
    endtask


endmodule