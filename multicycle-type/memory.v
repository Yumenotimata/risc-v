module Memory(
    input clk,
    input wire [31:0] memory_out_addr,memory_write_addr,
    input wire [31:0] memory_write_data,
    output wire[31:0] memory_out_data
);

    reg [7:0] m[0:65535];
    
    always @(*) begin
        m[memory_write_addr] <= memory_write_data;
    end

    assign memory_out_data = m[memory_out_addr];

    initial begin
        $readmemb("memory.hex",core.memory.m,16'h0,16'hffff);
    end

endmodule