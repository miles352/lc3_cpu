`timescale 1ns / 1ps



module alu(
    input [15:0] a,
    input [15:0] b,
    // add, and, not
    input [1:0] operation,
    output reg [15:0] out
    );
    
    
    always @ (a, b, operation) begin
        case (operation)
            2'b00: out <= a + b; // ADD
            2'b01: out <= a & b; // AND
            2'b10: out <= ~a;    // NOT
            default: begin
            end
        endcase
    end
endmodule
