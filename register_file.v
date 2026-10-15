`timescale 1ns / 1ps



module register_file(
    input clk,
    input write_enable,
    input [2:0] write_register,
    input [15:0] write_data,
    input [2:0] read_register_a,
    input [2:0] read_register_b,
    output [15:0] read_data_a,
    output [15:0] read_data_b
    );
    
    reg [15:0] registers[7:0];
    
    assign read_data_a = registers[read_register_a];
    assign read_data_b = registers[read_register_b];
    
    always @ (posedge clk) begin
        if (write_enable) begin
            registers[write_register] <= write_data;
        end
    end
    
endmodule
