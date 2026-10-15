`timescale 1ns / 1ps


module control_unit(
        input clk,
        input reset
    );
    
    reg [15:0] alu_a, alu_b;
    reg [1:0] alu_operation;
    wire [15:0] alu_out;
    
    alu alu(.a(alu_a), .b(alu_b), .operation(alu_operation), .out(alu_out));
    
    reg mem_write_enable;
    reg [15:0] mem_write_addr, mem_write_data;
    reg [15:0] mem_read_addr_a, mem_read_addr_b, mem_read_addr_c;
    wire [15:0] mem_read_data_a, mem_read_data_b, mem_read_data_c;
    
    memory mem(.clk(clk), .write_enable(mem_write_enable), .write_address(mem_write_addr), .write_data(mem_write_data), .read_address_a(mem_read_addr_a), .read_address_b(mem_read_addr_b), .read_address_c(mem_read_addr_c), .read_data_a(mem_read_data_a), .read_data_b(mem_read_data_b), .read_data_c(mem_read_data_c));
    
    reg rf_write_enable;
    reg [2:0] rf_write_reg;
    reg [15:0] rf_write_data;
    reg [2:0] rf_read_reg_a, rf_read_reg_b;
    reg [15:0] rf_read_data_a, rf_read_data_b;

    register_file rf(.clk(clk), .write_enable(rf_write_enable), .write_register(rf_write_reg), .write_data(rf_write_data), .read_register_a(rf_read_reg_a), .read_register_b(rf_read_reg_b), .read_data_a(rf_read_data_a), .read_data_b(rf_read_data_b));


    // condition codes
    reg c_n, c_z, c_p;

    reg [15:0] pc, pc_plus1, ir;
    wire [15:0] next_pc;

    wire [2:0] dr, sr1, sr2;
    wire [4:0] imm5;
    wire [15:0] imm5_sext;
    wire [5:0] offset6;
    wire [15:0] offset6_sext;
    wire [8:0] PCOffset9;
    wire [15:0] PCOffset9_sext;
    wire [10:0] PCOffset11;
    wire [15:0] PCOffset11_sext;
    wire [7:0] trapvect8;
    wire [3:0] opcode;
    wire alt_and_add, alt_jsr_jsrr;
    wire dr_insn;

    wire is_branch_insn, branch_taken;

    assign is_branch_insn = opcode == 4'b0000 // BR
                            || opcode == 4'b1100 // JMP
                            || opcode == 4'b0100 // JSR
                            || opcode == 4'b1111; // TRAP
    assign branch_taken = is_branch_insn && ((opcode != 4'b0000) // unconditional branch
                            || ((c_n & ir[11]) | (c_z & ir[10]) | (c_p & ir[9]))); // OR matches condition
    assign pc_plus1 = pc + 16'b1;
    assign next_pc = branch_taken ? alu_out : pc_plus1;

    assign dr_insn = opcode == 4'b0001 // ADD
                    || opcode == 4'b0101 // AND
                    || opcode == 4'b0010 // LD
                    || opcode == 4'b1010 // LDI
                    || opcode == 4'b0110 // LDR
                    || opcode == 4'b1110 // LEA
                    || opcode == 4'b1001; // NOT


    assign opcode = ir[15:12];
    assign dr = ir[11:9];
    assign sr1 = ir[8:6];
    assign alt_and_add = ir[5];
    assign alt_jsr_jsrr = ir[11];
    assign sr2 = ir[2:0];

    assign imm5 = ir[4:0];
    assign imm5_sext = {{11{imm5[4]}}, imm5};

    assign PCOffset9 = ir[8:0];
    assign PCOffset9_sext = {{7{PCOffset9[8]}}, PCOffset9};

    assign trapvect8 = ir[7:0];

    assign offset6 = ir[5:0];
    assign offset6_sext = {{10{offset6[5]}}, offset6};

    assign PCOffset11 = ir[10:0];
    assign PCOffset11_sext = {{5{PCOffset11[10]}}, PCOffset11};

    // datapath
    always @ (*) begin
        alu_a = 16'b0;
        alu_b = 16'b0;
        alu_operation = 2'b00; // ADD
        rf_write_enable = 1'b0;
        rf_read_reg_a = 3'b0;
        rf_read_reg_b = 3'b0;
        rf_write_reg = 3'b0;
        rf_write_data = 16'b0;
        mem_write_enable = 1'b0;
        mem_write_addr = 16'b0;
        mem_write_data = 16'b0;
        mem_read_addr_a = 16'b0;
        mem_read_addr_b = 16'b0;
        mem_read_addr_c = 16'b0;

        // fetch instruction
        mem_read_addr_a = pc;
        ir = mem_read_data_a;

        case (opcode)
            4'b0001: begin // ADD
                rf_read_reg_a = sr1;
                rf_read_reg_b = sr2;

                alu_a = rf_read_data_a;
                alu_b = alt_and_add ? imm5_sext : rf_read_data_b;

                alu_operation = 2'b00; // ADD

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = alu_out;
                
            end
            4'b0101: begin // AND
                rf_read_reg_a = sr1;
                rf_read_reg_b = sr2;

                alu_a = rf_read_data_a;
                alu_b = alt_and_add ? imm5_sext : rf_read_data_b;

                alu_operation = 2'b01; // AND

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = alu_out;
            end
            4'b0000: begin // BR
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;

                alu_operation = 2'b00; // ADD
            end
            4'b1100: begin // JMP / RET
                rf_read_reg_a = sr1;

                // ALU is not needed but next_pc comes from alu_out when a branch is taken
                alu_a = rf_read_data_a;
                alu_b = 16'b0;

                alu_operation = 2'b00; // ADD
            end
            4'b0100: begin // JSR / JSRR
                // r7 = pc
                rf_write_reg = 3'b111; // R7
                rf_write_enable = 1'b1;
                rf_write_data = pc_plus1;

                if (alt_jsr_jsrr) begin // JSR
                    alu_a = pc_plus1;
                    alu_b = PCOffset11_sext;
                end else begin // JSRR
                    rf_read_reg_a = sr1;
                    alu_a = rf_read_data_a;
                    alu_b = 16'b0;
                end
                alu_operation = 2'b00; // ADD
            end
            4'b0010: begin // LD
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;
                alu_operation = 2'b00; // ADD

                mem_read_addr_b = alu_out;

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = mem_read_data_b;
            end
            4'b1010: begin // LDI
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;
                alu_operation = 2'b00; // ADD

                mem_read_addr_b = alu_out;
                mem_read_addr_c = mem_read_data_b;
                
                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = mem_read_data_c;
            end
            4'b0110: begin // LDR
                rf_read_reg_a = sr1; // sr1 is BaseR
                alu_a = rf_read_data_a;
                alu_b = offset6_sext;
                alu_operation = 2'b00; // ADD

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = mem_read_data_b;
            end
            4'b1110: begin // LEA
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;
                alu_operation = 2'b00; // ADD

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = alu_out;
            end
            4'b1001: begin // NOT
                rf_read_reg_a = sr1;
                alu_a = rf_read_data_a;
                alu_operation = 2'b10; // NOT

                rf_write_enable = 1'b1;
                rf_write_reg = dr;
                rf_write_data = alu_out;
            end
            4'b1000: begin // RTI
                // To be implemented later
            end
            4'b0011: begin // ST
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;
                alu_operation = 2'b00; // ADD

                rf_read_reg_a = dr; // technically its a source register for store but its in the place of where dr usually is

                mem_write_enable = 1'b1;
                mem_write_addr = alu_out;
                mem_write_data = rf_read_data_a;
            end
            4'b1011: begin // STI
                alu_a = pc_plus1;
                alu_b = PCOffset9_sext;
                alu_operation = 2'b00; // ADD

                mem_read_addr_b = alu_out;

                rf_read_reg_a = dr;

                mem_write_enable = 1'b1;
                mem_write_addr = mem_read_data_b;
                mem_write_data = rf_read_data_a;
            end
            4'b0111: begin // STR
                rf_read_reg_a = sr1; // sr1 is BaseR
                alu_a = rf_read_data_a;
                alu_b = offset6_sext;
                alu_operation = 2'b00; // ADD

                rf_read_reg_a = dr;

                mem_write_enable = 1'b1;
                mem_write_addr = alu_out;
                mem_write_data = rf_read_data_a;
            end
            4'b1111: begin // TRAP
                rf_write_enable = 1'b1;
                rf_write_reg = 3'b111; // R7
                rf_write_data = pc_plus1;

                mem_read_addr_b = {8'b0, trapvect8};

                alu_a = mem_read_data_b;
                alu_b = 16'b0;
                alu_operation = 2'b00; // ADD
            end
            4'b1101: begin // reserved
            end
        endcase
    end


    // control path
    always @ (posedge clk) begin
        if (reset) begin
            pc <= 16'h3000;
            c_n <= 1'b0;
            c_z <= 1'b0;
            c_p <= 1'b0;
        end
        else begin
            pc <= next_pc;
            c_n <= dr_insn ? rf_write_data[15] : c_n;
            c_z <= dr_insn ? rf_write_data == 16'b0 : c_z;
            c_p <= dr_insn ? !rf_write_data[15] && rf_write_data != 16'b0 : c_p;
        end
    end
    
endmodule
