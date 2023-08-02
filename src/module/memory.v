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
        //�p�X���Ԉ���Ă���悤�Ɍ����邪�A���ۂ̎Q�Ƃ̓g�b�v���x���̃��W���[������Ȃ̂ł����Ă�BMakefile�\���ɂ�������肻��
        $readmemh("module/memory.hex",core.memory.m,16'h0,16'hffff);
    end

endmodule