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
    reg [31:0] csr [0:4095];

    integer i;
    initial begin
        stage <= `IF;
        pc <= 32'b0;
        for(i=0;i<32;i++) begin
            rs[i] <= i;
        end
        for(i=0;i<4095;i++) begin
            csr[i] <= i;
        end
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
    wire [31:0] imm_i_sext = {{20{imm_i[11]}},imm_i};
    wire [11:0] imm_s = {memory_read_data[31:25],memory_read_data[11:7]};
    wire [31:0] imm_s_sext = {{20{imm_s[11]}},imm_s};
    wire[12:0] imm_b = {memory_read_data[31],memory_read_data[7],{memory_read_data[30:25]},{memory_read_data[11:8]},{1'b0}};
    wire [31:0] imm_b_sext = {{19{imm_b[12]}},imm_b};
    wire [20:0] imm_j = {memory_read_data[31],memory_read_data[19:12],memory_read_data[20],memory_read_data[30:21],{1'b0}};
    wire [31:0] imm_j_sext = {{11{imm_j[20]}},imm_j};
    wire [19:0] imm_u = memory_read_data[31:12];
    wire [31:0] imm_u_shifted_sext = {imm_u,{12'b0}};
    wire [19:0] csr_addr = memory_read_data[31:20];
    wire [4:0] imm_z = memory_read_data[19:15];
    wire [31:0] imm_z_uext = {27'b0,imm_z};

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
        rs[0] <= 32'b0;
    end

    //Instruction Fetch
    reg inc_flag = 1'b0;
    reg [31:0] br_jmp = 32'b0;
    reg br_flag = 1'b0;
    reg [31:0] jmp = 32'b0;
    reg jmp_flag = 1'b0;
    task Fetch;
        begin
            if(inc_flag & !br_flag) begin
                pc <= pc + 4;
            end else if(br_flag) begin
                pc <= br_jmp;
                br_flag <= 1'b0;
            end
            if(jmp_flag) begin
                pc <= jmp; 
                jmp_flag <= 1'b0;
            end
            if(pc == 32'h0) begin
               inc_flag = 1'b1;
            end

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
                //ジャンプ命令のジャンプアドレス先計算って、命令フェッチ時のプログラムカウンタをベースにしたほうがいい？わからん
                //マルチサイクルなら問題ないけど、パイプライン実装したら命令フェッチ時のアドレスを逆算するだけでいいんかなしらんけど
                `BEQ    :   alu_out <= {(rs1 == rs2) ? (imm_b_sext + pc) : 32'b0};
                `BNE    :   alu_out <= {(rs1 != rs2) ? (imm_b_sext + pc) : 32'b0};
                `BLT    :   alu_out <= {($signed(rs1) < $signed(rs2)) ? (imm_b_sext + pc) : 32'b0};
                `BGE    :   alu_out <= {($signed(rs1) >= $signed(rs2)) ? (imm_b_sext + pc) : 32'b0};
                `BLTU   :   alu_out <= {(rs1 < rs2) ? (imm_b_sext + pc) : 32'b0};
                `BGEU   :   alu_out <= {(rs1 >= rs2) ? (imm_b_sext + pc) : 32'b0};
                `JAL    :   alu_out <= pc + imm_j_sext;
                `JALR   :   alu_out <= (rs[rs1_addr] + imm_i_sext) & (~32'b1);
                `LUI    :   alu_out <= imm_u_shifted_sext;
                `AUIPC  :   alu_out <= pc + imm_u_shifted_sext;
                //CSR命令のレジスタライトバックってCSRレジスタに書き込んだ後のデータなのか、書き込む前のデータなのかわからん
                //けど書き込み前のCSRレジスタのデータをライトバックしても意味ないから多分CSRに書き込むのが先なはず
                `CSRRW  :   alu_out <= rs[rs1_addr];
                `CSRRWI :   alu_out <= imm_z_uext;
                `CSRRS  :   alu_out <= csr[csr_addr] | rs[rs1_addr];
                `CSRRSI :   alu_out <= csr[csr_addr] | imm_z_uext;
                `CSRRC  :   alu_out <= csr[csr_addr] & (~rs[rs1_addr]);
                `CSRRCI :   alu_out <= csr[csr_addr] & (~imm_z_uext);
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
                `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI    :
                    begin
                        csr[csr_addr] <= alu_out;
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
                `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU    :
                    begin
                        if(alu_out != 32'b0) begin
                            br_flag <= 1'b1;
                            br_jmp <= alu_out;
                        end
                    end
                `JAL,`JALR    :
                    begin
                        jmp_flag <= 1'b1;
                        jmp <= alu_out;
                        rs[rd_addr] <= pc + 32'd4;
                    end
                `LUI,`AUIPC    :
                    begin
                        rs[rd_addr] <= alu_out;
                    end
                `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI    :
                    begin
                        rs[rd_addr] <= csr[csr_addr];
                    end
            endcase
        end
    endtask

endmodule