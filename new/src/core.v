`include "module/memory.v"
`include "../inc/instruction.h"
`include "../inc/consts.h"

module Core(
    input rst,
    input clk
);

//internal element
reg [31:0] pc = -32'h4;
reg [31:0] rs [0:31];
reg [31:0] csr [0:4095];
reg [31:0] jmp_addr = 32'h0;
reg jmp_flag = 1'b0;
integer i;
initial begin
    for(i=0;i<32;i++) begin
        rs[i] <= 32'h0;
        //rs[i] <= i;
    end
    for(i=0;i<4096;i++) begin
        csr[i] <= 32'h0;
    end
end

//Memory
reg memory_program_load = `MEM_UNLOAD;
reg memory_data_load = `MEM_UNLOAD;
reg memory_wen = `MEM_UNWRITE;
wire [31:0] memory_write_data;
wire [31:0] memory_read_data;
wire [31:0] memory_program_data;

Memory memory(
    .program_load(memory_program_load),
    .data_load(memory_data_load),
    .wen(memory_wen),
    .write_data(ex_mem_rs2_data),
    .read_data(memory_read_data),
    .program_data(memory_program_data),
    .write_addr(ex_mem_alu_out),
    .read_addr(ex_mem_alu_out),
    .program_addr(pc)
);

always @(*) begin
    rs[0] <= 32'b0;
    if(memory_program_load == `MEM_LOAD) begin
        #1 memory_program_load <= `MEM_UNLOAD;
    end
    if(memory_data_load == `MEM_LOAD) begin
        #1 memory_data_load <= `MEM_UNLOAD;
    end
    if(memory_wen == `MEM_WRITE) begin
        #1 memory_wen <= `MEM_UNWRITE;
    end
end

//Instruction Fetch
always @(posedge clk) begin
    if(jmp_flag == `RESERVE_JMP) begin
        pc <= jmp_addr;
        jmp_flag <= `NO_JMP;
    end else if(id_mem_stall_flag == 1'b1) begin
        pc <= pc;
        id_mem_stall_flag <= 1'b0;
    end else if(id_ex_stall_flag == 2'b1) begin
        pc <= pc;
        id_ex_stall_flag <= 2'd2;
    end else if(id_ex_stall_flag == 2'd2) begin
        pc <= pc;
        id_ex_stall_flag <= 2'd0;
    end else begin
        pc <= pc + 32'h4;
    end
    memory_program_load <= 1'b0;
end

//IF-ID Stage Register
reg [31:0] if_ie_inst,if_ie_pc;

always @(negedge clk) begin
    if(jmp_flag == `RESERVE_JMP) begin
        if_ie_inst <= `STALL;
    end else if(id_mem_stall_flag == 1'b1) begin
        if_ie_inst <= if_ie_inst;
        if_ie_pc <= if_ie_pc;
    end else if(id_ex_stall_flag == 2'd1) begin
        if_ie_inst <= if_ie_inst;
        if_ie_pc <= if_ie_pc;
    end else if(id_ex_stall_flag == 2'd2) begin
        if_ie_inst <= if_ie_inst;
        if_ie_pc <= if_ie_pc;
    end else begin
        if_ie_inst <= memory_program_data;
        if_ie_pc <= pc;
    end
    
end

//Instruction Decode
reg [31:0] id_rs1_data,id_rs2_data;
reg stall_flag = 1'b0;
reg [1:0] id_ex_stall_flag = 2'd0;
reg id_mem_stall_flag = 1'b0;

wire [4:0] id_rs1_addr = if_ie_inst[19:15];
wire [4:0] id_rs2_addr = if_ie_inst[24:20];

always @(posedge clk) begin
    //for data hazard
    if(((id_rs1_addr == ex_mem_rd_addr) || (id_rs2_addr == ex_mem_rd_addr))  && (id_ex_stall_flag == 2'd0) && (if_ie_inst != `STALL) && (id_ex_inst != `STALL)) begin
        if(ex_mem_inst != `BLTU) begin
            id_mem_stall_flag <= 1'b1;
        end
    end
    if(((id_rs1_addr == id_ex_rd_addr) || (id_rs2_addr == id_ex_rd_addr))  && (if_ie_inst != `STALL) && (id_ex_inst != `STALL)) begin
        //ここでは簡略化しているが，実際にはレジスタライトバックがある命令とのデータハザードのみに対応すべき
        //例えば,BLTU,BGEU命令ではレジスタライトバックを行わないが、命令セットの関係上不必要なデータハザードを発生させる場合がある。
        if((id_ex_inst != `BLTU) && (id_ex_inst != `BGEU)) begin
            id_ex_stall_flag <= 2'd1;
        end
    end
    //ここ、命令によってはレジスタロードがなくても読み込むレジスタ番号が重複する場合がある
    //x0レジスタの値をフォワーディングする場合、alu_outはゼロでない可能性がある
    if(id_rs1_addr == mem_wb_rd_addr) begin
        id_rs1_data <= {(id_rs1_addr != 5'h0) ? mem_wb_alu_out : 32'h0};     
    end else begin
        id_rs1_data <= rs[id_rs1_addr];
    end

    if(id_rs2_addr == mem_wb_rd_addr) begin
        id_rs2_data <= {(id_rs2_addr != 5'h0) ? mem_wb_alu_out : 32'h0};        
    end else begin
        id_rs2_data <= rs[id_rs2_addr];
    end
end

//ID_EX Stage Register
reg [31:0] id_ex_rs1_data,id_ex_rs2_data;
reg [31:0] id_ex_pc,id_ex_inst;

always @(negedge clk) begin
    id_ex_pc <= if_ie_pc;
    if(jmp_flag == `RESERVE_JMP) begin
        id_ex_inst <= `STALL;
        //これもストール処理
        id_ex_rs1_data <= 32'b0;
        id_ex_rs2_data <= 32'b0;
    end else if(id_ex_stall_flag == 2'd1) begin
        id_ex_inst <= `STALL;
        //これもストール処理
        //id_ex_rs1_data <= 32'b0;
        //id_ex_rs1_data <= 32'b0;
        //id_ex_rs2_data <= 32'b0;
    end else if(id_ex_stall_flag == 2'd2) begin
        id_ex_inst <= id_ex_inst;
        id_ex_rs2_data <= id_ex_rs2_data;
        id_ex_rs1_data <= id_ex_rs1_data;
    end else if(id_mem_stall_flag == 1'b1) begin
        id_ex_inst <= id_ex_inst;
        id_ex_rs2_data <= id_ex_rs2_data;
        id_ex_rs1_data <= id_ex_rs1_data;
    end else begin
        id_ex_inst <= if_ie_inst;
        id_ex_rs1_data <= id_rs1_data;
        id_ex_rs2_data <= id_rs2_data;
    end
end

//Execution
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
reg [31:0] alu_out;

always @(posedge clk) begin
    casez(id_ex_inst)
        `LW     :   alu_out <= id_ex_rs1_data + id_ex_imm_i_sext;
        `SW     :   alu_out <= id_ex_rs1_data + id_ex_imm_s_sext;
        `ADD    :   alu_out <= id_ex_rs1_data + id_ex_rs2_data;
        `SUB    :   alu_out <= id_ex_rs1_data - id_ex_rs2_data;   
        `ADDI   :   alu_out <= id_ex_rs1_data + id_ex_imm_i_sext;
        `AND    :   alu_out <= id_ex_rs1_data & id_ex_rs2_data;
        `OR     :   alu_out <= id_ex_rs1_data | id_ex_rs2_data;
        `XOR    :   alu_out <= id_ex_rs1_data ^ id_ex_rs2_data;
        `ANDI   :   alu_out <= id_ex_rs1_data & id_ex_imm_i_sext;
        `ORI    :   alu_out <= id_ex_rs1_data | id_ex_imm_i_sext;
        `XORI   :   alu_out <= id_ex_rs1_data ^ id_ex_imm_i_sext;
        `SLL    :   alu_out <= id_ex_rs1_data << id_ex_rs2_data[4:0];
        `SRL    :   alu_out <= id_ex_rs1_data >> id_ex_rs2_data[4:0];
        `SRA    :   alu_out <= $signed(id_ex_rs1_data) >>> id_ex_rs2_data[4:0];
        `SLLI   :   alu_out <= id_ex_rs1_data << id_ex_imm_i_sext[4:0];
        `SRLI   :   alu_out <= id_ex_rs1_data >> id_ex_imm_i_sext[4:0];
        `SRAI   :   alu_out <= $signed(id_ex_rs1_data) >>> id_ex_imm_i_sext[4:0];
        `SLT    :   alu_out <= {($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data)) ? 32'b1 : 32'b0};
        `SLTU   :   alu_out <= {(id_ex_rs1_data < id_ex_rs2_data) ? 32'b1 : 32'b0};
        `SLTI   :   alu_out <= {($signed(id_ex_rs1_data) < $signed(id_ex_imm_i_sext)) ? 32'b1 : 32'b0};
        `SLTIU  :   alu_out <= {(id_ex_rs1_data < id_ex_imm_i_sext) ? 32'b1 : 32'b0};
        `BEQ    :   alu_out <= {(id_ex_rs1_data == id_ex_rs2_data) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `BNE    :   alu_out <= {(id_ex_rs1_data != id_ex_rs2_data) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `BLT    :   alu_out <= {($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data)) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `BGE    :   alu_out <= {($signed(id_ex_rs1_data) >= $signed(id_ex_rs2_data)) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `BLTU   :   alu_out <= {(id_ex_rs1_data < id_ex_rs2_data) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `BGEU   :   alu_out <= {(id_ex_rs1_data >= id_ex_rs2_data) ? (id_ex_imm_b_sext + id_ex_pc) : `UN_MATCH};
        `JAL    :   alu_out <= id_ex_pc + id_ex_imm_j_sext;
        `JALR   :   alu_out <= (id_ex_rs1_data + id_ex_imm_i_sext) & (~32'b1);
        `LUI    :   alu_out <= id_ex_imm_u_shifted_sext;
        `AUIPC  :   alu_out <= id_ex_pc + id_ex_imm_u_shifted_sext;
        `CSRRW  :   alu_out <= id_ex_rs1_data;
        `CSRRWI :   alu_out <= id_ex_imm_z_uext;
        `CSRRS  :   alu_out <= csr[id_ex_csr_addr] | id_ex_rs1_data;
        `CSRRSI :   alu_out <= csr[id_ex_csr_addr] | id_ex_imm_z_uext;
        `CSRRC  :   alu_out <= csr[id_ex_csr_addr] & (~id_ex_rs1_data);
        `CSRRCI :   alu_out <= csr[id_ex_csr_addr] & (~id_ex_imm_z_uext);
    endcase
end

//EX_MEM Stage Register
reg [31:0] ex_mem_pc,ex_mem_inst,ex_mem_alu_out,ex_mem_rs1_data,ex_mem_rs2_data;
wire [4:0] ex_mem_rd_addr = ex_mem_inst[11:7];

always @(negedge clk) begin
    ex_mem_pc <= id_ex_pc;
    ex_mem_alu_out <= alu_out;
    ex_mem_rs1_data <= id_ex_rs1_data;
    ex_mem_rs2_data <= id_ex_rs2_data;
    //ex_mem_inst <= {(jmp_flag == `RESERVE_JMP) ? `STALL : id_ex_inst};
    if(jmp_flag == `RESERVE_JMP) begin
        ex_mem_inst <= `STALL;
    end else begin
        ex_mem_inst <= id_ex_inst;
    end
end

//Memory Access
wire [19:0] ex_mem_csr_addr = ex_mem_inst[31:20];

always @(posedge clk) begin
    casez(ex_mem_inst)
        `LW :
            begin
                memory_data_load <= `MEM_LOAD;
            end
        `SW :
            begin
                memory_wen <= `MEM_WRITE;
            end
        `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI :
            begin
                csr[ex_mem_csr_addr] <= ex_mem_alu_out;
            end
    endcase
end

//MEM-WB Stage Register
reg [31:0] mem_wb_inst,mem_wb_alu_out,mem_wb_memory_read_data,mem_wb_pc;

always @(negedge clk) begin
    mem_wb_inst <= {(jmp_flag == `RESERVE_JMP) ? `STALL : ex_mem_inst};
    if(mem_wb_inst == `LW) begin
        mem_wb_alu_out <= memory_read_data;
    end else begin
        mem_wb_alu_out <= ex_mem_alu_out;
    end
    mem_wb_pc <= ex_mem_pc;
end


//Write Back
wire [4:0] mem_wb_rd_addr = mem_wb_inst[11:7];
wire [19:0] mem_wb_csr_addr = mem_wb_inst[31:20];

always @(posedge clk) begin
    casez(mem_wb_inst)
        `LW :
            begin   
                rs[mem_wb_rd_addr] <= mem_wb_memory_read_data;
            end
        `ADD,`SUB,`ADDI,`AND,`OR,`XOR,`ANDI,`ORI,`XORI,`SLL,`SRL,`SRA,`SLLI,`SRLI,`SRAI,`SLT,`SLTU,`SLTI,`SLTIU :
            begin
                rs[mem_wb_rd_addr] <= mem_wb_alu_out;
            end
        `LUI,`AUIPC :
            begin
                rs[mem_wb_rd_addr] <= mem_wb_alu_out;
            end
        `CSRRW,`CSRRWI,`CSRRS,`CSRRSI,`CSRRC,`CSRRCI :
            begin
                rs[mem_wb_rd_addr] <= csr[mem_wb_csr_addr];
            end
        `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU :
            begin
                if(mem_wb_alu_out != 32'b0) begin
                    jmp_flag <= `RESERVE_JMP;
                    id_ex_stall_flag <= 2'd0;
                    id_mem_stall_flag <= 1'd0;
                end
                jmp_addr <= mem_wb_alu_out;
            end
        `JAL,`JALR :
            begin
                jmp_flag <= `RESERVE_JMP;
                jmp_addr <= mem_wb_alu_out;
                id_ex_stall_flag <= 2'd0;
                id_mem_stall_flag <= 1'd0;
                rs[mem_wb_rd_addr] <= mem_wb_pc + 32'h4;
            end
        `ECALL :
            begin
                jmp_flag <= `RESERVE_JMP;
                id_ex_stall_flag <= 2'd0;
                id_mem_stall_flag <= 1'd0;
                jmp_addr <= csr[12'h305];
                csr[12'h342] <= 32'd11;
            end
    endcase
end


endmodule