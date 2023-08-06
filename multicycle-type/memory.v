module Memory(
    input clk,
    input wire [31:0] memory_read_addr,memory_write_addr,
    input wire [31:0] memory_write_data,
    output wire[31:0] memory_read_data
);

    reg [7:0] m[0:65535];
    
    always @(*) begin
        m[memory_write_addr] <= memory_write_data;
    end

    assign memory_read_data = m[memory_read_addr];

endmodule