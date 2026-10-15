`timescale 1ns / 1ps



module memory(
    input clk,
    input write_enable,
    input [15:0] write_address,
    input [15:0] write_data,
    input [15:0] read_address_a, read_address_b, read_address_c,
    output [15:0] read_data_a, read_data_b, read_data_c
    );
    
    reg [15:0] data[2**16-1:0];
    
    assign read_data_a = data[read_address_a];
    assign read_data_b = data[read_address_b];
    assign read_data_c = data[read_address_c];

    initial begin
        $readmemh("shift_right.bin", data, 16'h3000);
    end
    
    always @ (posedge clk) begin
        if (write_enable) begin
            data[write_address] <= write_data;
        end
    end
    
    
endmodule
