module Memory(
    input load,wen,
    input wire [31:0] write_data,
    input wire [31:0] read_addr,write_addr,
    output reg [31:0] out_data
);

    reg [7:0] m[0:65535];

    always @(negedge load) begin
        out_data <= {m[read_addr+3],m[read_addr+2],m[read_addr+1],m[read_addr]};
    end

    always @(negedge wen) begin
        m[write_addr] <= write_data[7:0];
        m[write_addr+1] <= write_data[15:8];
        m[write_addr+2] <= write_data[23:16];
        m[write_addr+3] <= write_data[31:24];
    end


endmodule