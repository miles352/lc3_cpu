`timescale 1ns / 1ps

module test;

reg rst, clk;

initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, test);

    #10
    rst <= 1'b1;
    #5
    rst <= 1'b0;
    #50000
    $finish;
end

control_unit cu(.clk(clk), .reset(rst));


assign #5 clk = ~clk;



endmodule
