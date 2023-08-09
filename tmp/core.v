`include "consts.h"
`include "instruction.h"
`include "memory.v"

module Core(
    input rst,clk
);

    reg [2:0] stage;
    reg [31:0] pc;

    //Register
    reg [31:0] rs [0:31];

    integer i;
    initial begin
        stage <= `IF;
        pc <= 32'b0;
        for(i=0;i<32;i++) begin
            rs[i] <= i;
        end
        rs[1] <= -32'd10;
    end

    reg [31:0] alu_out;

    //Memory
    reg memory_load,memory_wen,memory_d_load;
    reg [31:0] memory_write_addr;
    reg [31:0] memory_write_data;
    wire [31:0] memory_read_data,memory_d_read_data;
    Memory memory(
        .load(memory_load),
        .wen(memory_wen),
        .d_load(memory_d_load),
        .read_addr(pc),
        .d_read_addr(alu_out),
        .write_addr(alu_out),
        .write_data(memory_write_data),
        .out_data(memory_read_data),
        .d_out_data(memory_d_read_data)
    );
    initial begin
        memory_load <= `MEM_UNLOAD;
        memory_wen <= `MEM_UNWRITE;
        memory_d_load <= `MEM_UNLOAD;
        memory_write_addr <= 32'h0;
        memory_write_data <= 32'h0;
    end

    //Decoder
    wire [4:0] rs1_addr = memory_read_data[19:15]; 
    wire [4:0] rs2_addr = memory_read_data[24:20];
    wire [4:0] rd_addr = memory_read_data[11:7];
    wire [31:0] rs1,rs2;
    wire [11:0] imm_i = memory_read_data[31:20];
    wire [31:0] imm_i_sext = {{20{memory_read_data[31]}},imm_i};
    wire [11:0] imm_s = {memory_read_data[31:25],memory_read_data[11:7]};
    wire [31:0] imm_s_sext = {{20{memory_read_data[31]}},imm_s};

    always @(posedge clk) begin
        if((stage == `WB) || rst) begin
            stage <= `IF;
        end
        else begin
            stage <= stage + 1; 
        end
    end

    always @(*) begin
        casez(stage)
            `IF     :   Fetch();
            `ID     :   Decode();
            `EX     :   Execute();
            `MEM    :   MemoryAccess();
            `WB     :   WriteBack();
        endcase
    end

    //Instruction Fetch
    integer inc_flag = 0;
    task Fetch;
        begin
            if(inc_flag)
                pc <= pc + 4; 
            if(pc == 32'h0)
               inc_flag = 1;

            memory_load <= `MEM_LOAD;
            //1ps 
            #1 memory_load <= `MEM_UNLOAD;
        end
    endtask

    //Instruction Decode
    assign rs1 = rs[rs1_addr];
    assign rs2 = rs[rs2_addr];
    task Decode;
        begin
            
        end
    endtask

    //Execution
    
    task Execute;
        begin
            casez(memory_read_data)
                `LW     :   alu_out <= rs1 + imm_i_sext;
                `SW     :   alu_out <= rs1 + imm_s_sext;
                `ADD    :   alu_out <= rs1 + rs2;
                `SUB    :   alu_out <= rs1 - rs2;   
                `ADDI   :   alu_out <= rs1 + imm_i_sext;
                `AND    :   alu_out <= rs1 & rs2;
                `OR     :   alu_out <= rs1 | rs2;
                `XOR    :   alu_out <= rs1 ^ rs2;
                `ANDI   :   alu_out <= rs1 & imm_i_sext;
                `ORI    :   alu_out <= rs1 | imm_i_sext;
                `XORI   :   alu_out <= rs1 ^ imm_i_sext;
                `SLL    :   alu_out <= rs1 << rs2[4:0];
                `SRL    :   alu_out <= rs1 >> rs2[4:0];
                `SRA    :   alu_out <= $signed(rs1) >>> rs2[4:0];
                `SLLI   :   alu_out <= rs1 << imm_i_sext[4:0];
                `SRLI   :   alu_out <= rs1 >> imm_i_sext[4:0];
                `SRAI   :   alu_out <= $signed(rs1) >>> imm_i_sext[4:0];
                `SLT    :   alu_out <= {($signed(rs1) < $signed(rs2)) ? 32'b1 : 32'b0};
                `SLTU   :   alu_out <= {(rs1 < rs2) ? 32'b1 : 32'b0};
                `SLTI   :   alu_out <= {($signed(rs1) < $signed(imm_i_sext)) ? 32'b1 : 32'b0};
                `SLTIU  :   alu_out <= {(rs1 < imm_i_sext) ? 32'b1 : 32'b0};
            endcase
        end
    endtask

    //Memory Access
    task MemoryAccess;
        begin
            casez(memory_read_data)
                `LW    :   
                    begin
                        memory_d_load <= `MEM_LOAD;
                    end
                `SW     :
                    begin
                        memory_write_data <= rs2;
                        memory_wen <= `MEM_WRITE;
                    end
            endcase
            #1 memory_d_load <= `MEM_UNLOAD;
            #1 memory_wen <= `MEM_UNWRITE;
        end
    endtask

    //Write Back
    task WriteBack;
        begin
            casez(memory_read_data)
                `LW     :   rs[rd_addr] <= memory_d_read_data;
                `ADD,`SUB,`ADDI,`AND,`OR,`XOR,`ANDI,`ORI,`XORI,`SLL,`SRL,`SRA,`SLLI,`SRLI,`SRAI,`SLT,`SLTU,`SLTI,`SLTIU   :
                    begin
                        rs[rd_addr] <= alu_out;
                    end
            endcase
        end
    endtask

endmodule