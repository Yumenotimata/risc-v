module Memory(
        input load,
        input wire[31:0] addr,
        output reg[31:0] data
    );

    reg [7:0] m[0:65535];

    always @(negedge load) begin
        data <= {m[addr+3],m[addr+2],m[addr+1],m[addr]};
    end
    
    initial begin
        //パスが間違っているように見えるが、実際の参照はトップレベルのモジュールからなのであってる。Makefile構成にしたら沼りそう
        $readmemh("module/memory.hex",core.memory.m,16'h0,16'hffff);
    end

endmodule