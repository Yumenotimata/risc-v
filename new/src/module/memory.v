module Memory(
    input program_load,data_load,wen,
    output reg [31:0] write_data,read_data,program_data,
    input wire [31:0] write_addr,read_addr,program_addr
);

reg [7:0] m[0:65535];

always @(negedge program_load) begin
    program_data = {m[program_addr+3],m[program_addr+2],m[program_addr+1],m[program_addr]};
end

endmodule