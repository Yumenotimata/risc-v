module Memory(
    input program_load,data_load,wen,
    output reg [31:0] read_data,program_data,
    input wire [31:0] write_addr,read_addr,program_addr,
    input wire [31:0] write_data
);

reg [7:0] m[0:65535];

always @(negedge program_load) begin
    program_data = {m[program_addr+3],m[program_addr+2],m[program_addr+1],m[program_addr]};
end

always @(negedge data_load) begin
    read_data = {m[read_addr+3],m[read_addr+2],m[read_addr+1],m[read_addr]};
end

always @(negedge wen) begin
    m[write_addr] <= write_data[7:0];
    m[write_addr+1] <= write_data[15:8];
    m[write_addr+2] <= write_data[23:16];
    m[write_addr+3] <= write_data[31:24];
end

endmodule