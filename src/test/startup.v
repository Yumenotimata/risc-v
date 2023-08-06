`timescale 1ns/1ps
`include "test.v"

module startup;

    parameter step = 10;
    parameter ticks = 40;

    reg clk;
    reg rst;

    test t(
        .clk(clk)
    );

    integer i;
    initial
        begin
            $dumpfile("wave.vcd");
            $dumpvars(0,t);
        end

    initial
        begin
            clk = 1'b1;
            forever
                begin
                    #(step/2) clk = !clk;
                end
        end

    initial
        begin
            rst = 1'b0;
            repeat (1) @(posedge clk) rst <= 1'b1;
            @(posedge clk) rst <= 1'b0;
        end

    initial
       begin
           repeat (ticks) @(posedge clk);
           $finish;
       end

endmodule