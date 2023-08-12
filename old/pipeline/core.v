`include "consts.h"
`include "instruction.h"
`include "memory.v"

module Core(
    input rst,clk
);

    reg [31:0] if_pc = 32'h0;

    //Register
    reg [31:0] rs [0:31];
    reg [31:0] csr [0:4095];

    integer i;
    initial begin

        for(i=0;i<32;i++) begin
            rs[i] <= i;
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
        .read_addr(if_pc),
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
    wire[12:0] imm_b = {memory_read_data[31],memory_read_data[7],memory_read_data[30:25],memory_read_data[11:8],1'b0};
    wire [31:0] imm_b_sext = {{19{imm_b[12]}},imm_b};
    wire [20:0] imm_j = {memory_read_data[31],memory_read_data[19:12],memory_read_data[20],memory_read_data[30:21],{1'b0}};
    wire [31:0] imm_j_sext = {{11{imm_j[20]}},imm_j};
    wire [19:0] imm_u = memory_read_data[31:12];
    wire [31:0] imm_u_shifted_sext = {imm_u,{12'b0}};
    wire [19:0] csr_addr = memory_read_data[31:20];
    wire [4:0] imm_z = memory_read_data[19:15];
    wire [31:0] imm_z_uext = {27'b0,imm_z};


    reg clk_flag = 1'b0;

    always @(*) begin
        if(clk & (!clk_flag)) begin
            if(if_pc == 32'h0) begin
                init_flag <= 1'b1;
            end
            if(init_flag == 1'b1) begin
                if_pc <= if_pc + 32'h4;
            end
            clk_flag <= 1'b1;
            Fetch();
            Decode();
            Execute();
            MemoryAccess();
            WriteBack();
            rs[0] <= 32'b0;
        end
        if((!clk) & clk_flag) begin
            clk_flag <= 1'b0;
        end
    end

    always @(negedge clk) begin
    end

    //Instruction Fetch
    reg init_flag = 1'b0;
    reg [31:0] br_jmp = 32'b0;
    reg br_flag = 1'b0;
    reg [31:0] jmp = 32'b0;
    reg jmp_flag = 1'b0;

    //クソポイント
    task Fetch;
        begin
            memory_load <= `MEM_LOAD;
        end
    endtask

    
    always @(posedge clk) begin
        if(if_pc == 32'b0) begin
            init_flag <= 1'b1;
        end else if(jmp_flag) begin
            if_pc <= jmp;
            jmp_flag <= 1'b0;
        end else if(br_flag) begin
            if_pc <= br_jmp;
            br_flag <= 1'b0;
        end else if(init_flag == 1'b1) begin
            if_pc <= if_pc + 32'h4;
        end
        
    end

    reg [31:0] if_id_pc,if_id_inst;
    always @(negedge clk) begin
        if(jmp_flag) begin
            if_id_inst <= `STALL;
        end else if(br_flag) begin
            if_id_inst <= `STALL;
        end else begin
            if_id_inst <= memory_read_data;    
        end
        if_id_pc <= if_pc;
    end
    wire [4:0] if_id_rs1_addr = if_id_inst[19:15];
    wire [4:0] if_id_rs2_addr = if_id_inst[24:20];


    //Instruction Decode
    assign rs1 = rs[rs1_addr];
    assign rs2 = rs[rs2_addr];
    task Decode;
        begin
            
        end
    endtask

    reg [31:0] id_ex_pc,id_ex_inst;
    reg [31:0] id_ex_rs1;
    reg [31:0] id_ex_rs2;
    always @(negedge clk) begin
        id_ex_pc <= if_id_pc;
        if(jmp_flag | br_flag) begin
            id_ex_inst <= `STALL;
        end else begin
            id_ex_inst <= if_id_inst;
        end
        //分岐ハザード処理
        if(if_id_rs1_addr == mem_wb_rd_addr) begin
            id_ex_rs1 <= mem_wb_alu_out;
        end else begin
            id_ex_rs1 <= rs[if_id_rs1_addr];
        end
        if(if_id_rs2_addr == mem_wb_rd_addr) begin
            id_ex_rs2 <= rs[if_id_rs2_addr];
        end else begin
            id_ex_rs2 <= rs[if_id_rs2_addr];
        end
    end
    

    //Execution
    //Sub Decode
    wire [4:0] id_ex_rd_addr = id_ex_inst[11:7];  
    wire [11:0] id_ex_imm_i = id_ex_inst[31:20];
    wire [31:0] id_ex_imm_i_sext = {{20{id_ex_imm_i[11]}},id_ex_imm_i};
    wire [11:0] id_ex_imm_s = {id_ex_inst[31:25],id_ex_inst[11:7]};
    wire [31:0] id_ex_imm_s_sext = {{20{id_ex_imm_s[11]}},id_ex_imm_s};
    wire [12:0] id_ex_imm_b = {id_ex_inst[31],id_ex_inst[7],id_ex_inst[30:25],id_ex_inst[11:8],1'b0};
    wire [31:0] id_ex_imm_b_sext = {{19{id_ex_imm_b[12]}},id_ex_imm_b};
    wire [20:0] id_ex_imm_j = {id_ex_inst[31],id_ex_inst[19:12],id_ex_inst[20],id_ex_inst[30:21],{1'b0}};
    wire [31:0] id_ex_imm_j_sext = {{11{id_ex_imm_j[20]}},id_ex_imm_j};
    wire [19:0] id_ex_imm_u = id_ex_inst[31:12];
    wire [31:0] id_ex_imm_u_shifted_sext = {id_ex_imm_u,{12'b0}};
    wire [19:0] id_ex_csr_addr = id_ex_inst[31:20];
    wire [4:0]  id_ex_imm_z = id_ex_inst[19:15];
    wire [31:0] id_ex_imm_z_uext = {27'b0,id_ex_imm_z};  

    task Execute;
        begin
            casez(id_ex_inst)
                `LW     :   alu_out <= id_ex_rs1 + id_ex_imm_i_sext;
                `SW     :   alu_out <= id_ex_rs1 + id_ex_imm_s_sext;
                `ADD    :   alu_out <= id_ex_rs1 + id_ex_rs2;
                `SUB    :   alu_out <= id_ex_rs1 - id_ex_rs2;   
                `ADDI   :   alu_out <= id_ex_rs1 + id_ex_imm_i_sext;
                `AND    :   alu_out <= id_ex_rs1 & id_ex_rs2;
                `OR     :   alu_out <= id_ex_rs1 | id_ex_rs2;
                `XOR    :   alu_out <= id_ex_rs1 ^ id_ex_rs2;
                `ANDI   :   alu_out <= id_ex_rs1 & id_ex_imm_i_sext;
                `ORI    :   alu_out <= id_ex_rs1 | id_ex_imm_i_sext;
                `XORI   :   alu_out <= id_ex_rs1 ^ id_ex_imm_i_sext;
                `SLL    :   alu_out <= id_ex_rs1 << id_ex_rs2[4:0];
                `SRL    :   alu_out <= id_ex_rs1 >> id_ex_rs2[4:0];
                `SRA    :   alu_out <= $signed(id_ex_rs1) >>> id_ex_rs2[4:0];
                `SLLI   :   alu_out <= id_ex_rs1 << id_ex_imm_i_sext[4:0];
                `SRLI   :   alu_out <= id_ex_rs1 >> id_ex_imm_i_sext[4:0];
                `SRAI   :   alu_out <= $signed(id_ex_rs1) >>> id_ex_imm_i_sext[4:0];
                `SLT    :   alu_out <= {($signed(id_ex_rs1) < $signed(id_ex_rs2)) ? 32'b1 : 32'b0};
                `SLTU   :   alu_out <= {(id_ex_rs1 < id_ex_rs2) ? 32'b1 : 32'b0};
                `SLTI   :   alu_out <= {($signed(id_ex_rs1) < $signed(id_ex_imm_i_sext)) ? 32'b1 : 32'b0};
                `SLTIU  :   alu_out <= {(id_ex_rs1 < id_ex_imm_i_sext) ? 32'b1 : 32'b0};
                //ジャンプ命令のジャンプアドレス先計算って、命令フェッチ時のプログラムカウンタをベースにしたほうがいい？わからん
                //マルチサイクルなら問題ないけど、パイプライン実装したら命令フェッチ時のアドレスを逆算するだけでいいんかなしらんけど
                `BEQ    :   alu_out <= {(id_ex_rs1 == id_ex_rs2) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `BNE    :   alu_out <= {(id_ex_rs1 != id_ex_rs2) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `BLT    :   alu_out <= {($signed(id_ex_rs1) < $signed(id_ex_rs2)) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `BGE    :   alu_out <= {($signed(id_ex_rs1) >= $signed(id_ex_rs2)) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `BLTU   :   alu_out <= {(id_ex_rs1 < id_ex_rs2) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `BGEU   :   alu_out <= {(id_ex_rs1 >= id_ex_rs2) ? (id_ex_imm_b_sext + id_ex_pc) : 32'b0};
                `JAL    :   alu_out <= id_ex_pc + id_ex_imm_j_sext;
                `JALR   :   alu_out <= (id_ex_rs1 + id_ex_imm_i_sext) & (~32'b1);
                `LUI    :   alu_out <= id_ex_imm_u_shifted_sext;
                `AUIPC  :   alu_out <= id_ex_pc + id_ex_imm_u_shifted_sext;
                //CSR命令のレジスタライトバックってCSRレジスタに書き込んだ後のデータなのか、書き込む前のデータなのかわからん
                //けど書き込み前のCSRレジスタのデータをライトバックしても意味ないから多分CSRに書き込むのが先なはず
                `CSRRW  :   alu_out <= id_ex_rs1;
                `CSRRWI :   alu_out <= id_ex_imm_z_uext;
                `CSRRS  :   alu_out <= csr[id_ex_csr_addr] | id_ex_rs1;
                `CSRRSI :   alu_out <= csr[id_ex_csr_addr] | id_ex_imm_z_uext;
                `CSRRC  :   alu_out <= csr[id_ex_csr_addr] & (~id_ex_rs1);
                `CSRRCI :   alu_out <= csr[id_ex_csr_addr] & (~id_ex_imm_z_uext);
            endcase
        end
    endtask

    reg [31:0] ex_mem_pc,ex_mem_inst,ex_mem_alu_out,ex_mem_rs1,ex_mem_rs2;
    always @(negedge clk) begin
        ex_mem_pc <= id_ex_pc;
        ex_mem_inst <= id_ex_inst;
        ex_mem_alu_out <= alu_out;
        ex_mem_rs1 <= id_ex_rs1;
        ex_mem_rs2 <= id_ex_rs2;
    end

    //Sub Decode
    wire [19:0] ex_mem_csr_addr = ex_mem_inst[31:20];

    //Memory Access
    task MemoryAccess;
        begin
            casez(ex_mem_inst)
                `LW    :   
                    begin
                        memory_d_load <= `MEM_LOAD;
                    end
                `SW     :
                    begin
                        memory_write_data <= ex_mem_rs2;
                        memory_wen <= `MEM_WRITE;
                    end
                `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI    :
                    begin
                        csr[ex_mem_csr_addr] <= ex_mem_alu_out;
                    end
                `ECALL      :
                    begin
                        csr[12'h342] <= 32'd11;
                    end    
            endcase
        end
    endtask

    always @(*) begin
        if(memory_d_load == `MEM_LOAD) begin
            #1 memory_d_load <= `MEM_UNLOAD;
        end
        if(memory_load == `MEM_LOAD) begin
            #1 memory_load <= `MEM_UNLOAD;
        end
        if(memory_wen <= `MEM_WRITE) begin
            #1 memory_wen <= `MEM_UNWRITE;
        end

    end


    reg [31:0] mem_wb_inst,mem_wb_alu_out;
    always @(negedge clk) begin
        mem_wb_inst <= ex_mem_inst;
        mem_wb_alu_out <= ex_mem_alu_out;
    end

    //Sub Decode 
    wire [4:0] mem_wb_rd_addr = mem_wb_inst[11:7];
    wire [19:0] mem_wb_csr_addr = mem_wb_inst[31:20];
    //Write Back
    task WriteBack;
        begin
            casez(mem_wb_inst)
                `LW     :   rs[mem_wb_rd_addr] <= memory_d_read_data;
                `ADD,`SUB,`ADDI,`AND,`OR,`XOR,`ANDI,`ORI,`XORI,`SLL,`SRL,`SRA,`SLLI,`SRLI,`SRAI,`SLT,`SLTU,`SLTI,`SLTIU   :
                    begin
                        rs[mem_wb_rd_addr] <= mem_wb_alu_out;
                    end
                `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU    :
                    begin
                        if(mem_wb_alu_out != 32'b0) begin
                            br_flag <= 1'b1;
                            br_jmp <= mem_wb_alu_out;
                        end
                    end
                `JAL,`JALR    :
                    begin
                        jmp_flag <= 1'b1;
                        jmp <= mem_wb_alu_out;
                        //rs[rd_addr] <= pc + 32'd4;
                    end
                `LUI,`AUIPC    :
                    begin
                        rs[mem_wb_rd_addr] <= mem_wb_alu_out;
                    end
                `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI    :
                    begin
                        rs[mem_wb_rd_addr] <= csr[mem_wb_csr_addr];
                    end
                `ECALL      :
                    begin
                        jmp_flag <= 1'b1;
                        jmp <= csr[12'h305];
                    end
            endcase
        end
    endtask

endmodule