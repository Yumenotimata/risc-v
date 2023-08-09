`include "consts.h"
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
    end

    //Memory
    reg memory_load,memory_wen;
    reg [31:0] memory_write_addr;
    reg [31:0] memory_write_data;
    wire [31:0] memory_read_data;
    Memory memory(
        .load(memory_load),
        .wen(memory_wen),
        .read_addr(pc),
        .write_addr(memory_write_addr),
        .write_data(memory_write_data),
        .out_data(memory_read_data)
    );
    initial begin
        memory_load <= `MEM_UNLOAD;
        memory_wen <= `MEM_UNWRITE;
        memory_write_addr <= 32'h0;
        memory_write_data <= 32'h0;
    end

    //Decoder
    wire [4:0] rs1_addr = memory_read_data[19:15]; 
    wire [4:0] rs2_addr = memory_read_data[24:20];
    wire [4:0] rd_addr = memory_read_data[11:7];
    wire [31:0] rs1,rs2;

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
            //5ps ’x‰„
            #5 memory_load <= `MEM_UNLOAD;
        end
    endtask

    //Instruction Decode
    assign rs1 = rs[rs1_addr];
    assign rs2 = rs[rs2_addr];
    task Decode;
        begin
            
        end
    endtask

endmodule