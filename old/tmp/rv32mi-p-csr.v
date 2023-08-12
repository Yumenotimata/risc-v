`timescale 1ns/1ps
`include "core.v"
  
module startup;

    parameter step = 10;
    parameter ticks = 5000;
    parameter memory_hex = "build/riscv-tests-hex/rv32mi-p-csr.hex";
    parameter result_file_path = "result/rv32mi-p-csr.txt";

    reg clk;
    reg rst;

    Core core(
        .clk(clk),
        .rst(rst)
        );
    initial begin
        $readmemh(memory_hex,core.memory.m,16'h0,16'hffff);
        //$readmemh("mem.hex",core.memory.m,16'h0,16'hffff);
    end

    integer i;
    initial
        begin
            $dumpfile("vcd/rv32mi-p-csr.vcd");
            $dumpvars(0,core);
            for(i=0;i<32;i++) begin
               $dumpvars(1,core.memory.m[i]);
            end
            for(i=0;i<31;i++) begin
                $dumpvars(2,core.rs[i]);
            end
            for(i=0;i<31;i++) begin
                $dumpvars(3,core.csr[i]);
            end
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

    integer fp;

    initial
       begin
           repeat (ticks) begin
                @(posedge clk);
                if(core.pc == 32'h44) begin
                    fp = $fopen(result_file_path);
                    if(core.rs[3] == 32'b1) begin
                        $fdisplay(fp,"passed");
                    end else begin
                        $fdisplay(fp,"failed");
                    end
                    $fclose(fp);
                    $finish;
                end
           end
           $finish;
       end

endmodule