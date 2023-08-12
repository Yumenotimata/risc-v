module Memory(
        input load,
        input d_load,
        input wen,
        //for intruction fetch
        input wire[31:0] addr,
        input wire[31:0] w_data,
        //for data access
        input wire[31:0] d_addr,
        output reg[31:0] data,d_data
    );

    reg [7:0] m[0:65535];

    always @(negedge load) begin
        data <= {m[addr+3],m[addr+2],m[addr+1],m[addr]};
    end

    always @(negedge d_load) begin
        d_data <= {m[d_addr+3],m[d_addr+2],m[d_addr+1],m[d_addr]};
    end

    always @(negedge wen) begin
        $monitor("en");
        m[d_addr] <= w_data[7:0];
        m[d_addr+1] <= w_data[15:8];
        m[d_addr+2] <= w_data[23:16];
        m[d_addr+3] <= w_data[31:24];
    end
    
    initial begin
        //パスが間違っているように見えるが、実際の参照はトップレベルのモジュールからなのであってる。Makefile構成にしたら沼りそう
        $readmemh("module/add_test.hex",core.memory.m,16'h0,16'hffff);
    end

endmodule