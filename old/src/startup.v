`timescale 1ns/1ps
`include "cpu/core.v"

module startup;

    parameter step = 10;
    parameter ticks = 40;

    reg clk;
    reg rst;

    Core core(
        .clk(clk),
        .rst(rst)
        );

    integer i;
    initial
        begin
            $dumpfile("wave.vcd");
            $dumpvars(0,core);
            for(i=0;i<8;i++) begin
                $dumpvars(1,core.register[i]);
            end
            for(i=0;i<32;i++) begin
                $dumpvars(2,core.memory.m[i]);
            end
            $monitor("pc");
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