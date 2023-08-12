`timescale 1ns/1ps

module test(input clk);

    reg [7:0] a,b;

    always @(*) begin
        a<=8'd7;
        b<=8'd8;
        $monitor(a+b);
    end


endmodule