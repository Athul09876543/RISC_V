`timescale 1ns / 1ps

//..............................................Program Counter..............................//
module program_counter(
    input clk,                 
    input rst,                 
    input [31:0] pc_in,        
    output reg [31:0] pc_out  
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0;  
        end else begin
            pc_out <= pc_in;  
        end
    end

endmodule

//............................................PC Adder .......................................//
module pc_adder(
    input [31:0] pc_in,        
    output reg [31:0] pc_next  
);

    always @(*) begin
        pc_next = pc_in + 4;  
    end

endmodule

//...........................................PC Mux(2x1).......................................//
module pc_mux(
    input [31:0] pc_in,        
    input [31:0] pc_branch,   
    input pc_select,          
    output reg [31:0] pc_out  
);
    always @(*) begin
        if (pc_select == 1'b0) begin
            pc_out = pc_in;  
        end else begin
            pc_out = pc_branch;      
        end
    end

endmodule

//.........................................Instruction Memory................................//
module Instruction_Memory(
    input rst, 
    input clk, 
    input [31:0] read_address, 
    output [31:0] instruction_out
);

    // Expanded to 128 elements to prevent out-of-bounds errors for indices up to 110
    reg [31:0] I_Mem [127:0];  
    integer k;
    
    // Convert byte-addressing from PC to word-addressing for the array
    assign instruction_out = I_Mem[read_address >> 2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 128; k = k + 1) begin 
                I_Mem[k] <= 32'b0;  
            end
        end else begin
            // R-type
            I_Mem[0]  <= 32'b00000000000000000000000000000000;    // no operation
            I_Mem[1]  <= 32'b0000000_11001_10000_000_01101_0110011; // add x13, x16, x25 (Address 4)
            I_Mem[2]  <= 32'b0100000_00011_01000_000_00101_0110011; // sub x5, x8, x3     (Address 8)
            I_Mem[3]  <= 32'b0000000_00011_00010_111_00001_0110011; // and x1, x2, x3     (Address 12)
            I_Mem[4]  <= 32'b0000000_00101_00011_110_00100_0110011; // or x4, x3, x5      (Address 16)
            I_Mem[5]  <= 32'b0000000_00101_00011_100_00100_0110011; // xor x4, x3, x5     (Address 20)
            I_Mem[6]  <= 32'b0000000_00101_00011_001_00100_0110011; // sll x4, x3, x5     (Address 24)
            I_Mem[7]  <= 32'b0000000_00101_00011_101_00100_0110011; // srl x4, x3, x5     (Address 28)
            I_Mem[8]  <= 32'b0100000_00010_00011_101_00101_0110011; // sra x5, x3, x2     (Address 32)
            I_Mem[9]  <= 32'b0000000_00010_00011_010_00101_0110011; // slt x5, x3, x2     (Address 36)
            // I-type
            I_Mem[10] <= 32'b000000000010_10101_000_10110_0010011; // addi x22, x21, 2   (Address 40)
            I_Mem[11] <= 32'b000000000011_01000_110_01001_0010011; // ori x9, x8, 3      (Address 44) 
            I_Mem[12] <= 32'b000000000100_01000_110_01001_0010011; // xori x9, x8, 4     (Address 48)
            I_Mem[13] <= 32'b000000000101_00010_111_00001_0010011; // andi x1, x2, 5     (Address 52)
            I_Mem[14] <= 32'b000000000110_00011_001_00100_0010011; // slli x4, x3, 6     (Address 56)
            I_Mem[15] <= 32'b000000000111_00011_101_00100_0010011; // srli x4, x3, 7     (Address 60) 
            I_Mem[16] <= 32'b000000001000_00011_101_00101_0010011; // srai x5, x3, 8     (Address 64)
            I_Mem[17] <= 32'b000000001001_00011_010_00101_0010011; // slti x5, x3, 9     (Address 68)  
            // L-type
            I_Mem[18] <= 32'b000000000101_00011_000_01001_0000011; // lb x9, 5(x3)       (Address 72)
            I_Mem[19] <= 32'b000000000011_00011_001_01001_0000011; // lh x9, 3(x3)       (Address 76)
            I_Mem[20] <= 32'b000000001111_00010_010_01000_0000011; // lw x8, 15(x2)      (Address 80) 
            // S-type
            I_Mem[21] <= 32'b0000000_01111_00011_000_01000_0100011; // sb x15, 8(x3)     (Address 84)
            I_Mem[22] <= 32'b0000000_01110_00110_001_01010_0100011; // sh x14, 10(x6)    (Address 88)
            I_Mem[23] <= 32'b0000000_01110_00110_010_01100_0100011; // sw x14, 12(x6)    (Address 92)     
            // B-type    
            I_Mem[24] <= 32'b0_000000_01001_01001_000_0110_0_1100011; // beq x9, x9, 12  (Address 96) 
            I_Mem[25] <= 32'b0_000000_01001_01001_001_0111_0_1100011; // bne x9, x9, 14  (Address 100)
            // U-type
            I_Mem[26] <= 32'b00000000000000101000_00011_0110111; // lui x3, 40           (Address 104)
            I_Mem[27] <= 32'b0000000000000010100_00101_0010111;  // auipc x5, 20         (Address 108)
            // J-type
            I_Mem[28] <= 32'b0_00000000_0_0000010100_00001_1101111; // jal x1, 20        (Address 112)
        end
    end

endmodule

//................................................Register File............................................//
module Register_File(
    input clk, rst, RegWrite,
    input [4:0] Rs1, Rs2, Rd,
    input [31:0] Write_data,
    output [31:0] read_data1, read_data2
);

    reg [31:0] Registers [31:0];
    integer k;

    // Use asynchronous/synchronous structure correctly, avoid mixed style initial bugs
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1) begin
                Registers[k] <= 32'b0;
            end
        end else if (RegWrite && (Rd != 5'b0)) begin // RISC-V safeguard: x0 is always 0
            Registers[Rd] <= Write_data;
        end
    end

    // Initial default values for verification
    initial begin
        Registers[0] = 0;   Registers[1] = 3;   Registers[2] = 2;   Registers[3] = 12;
        Registers[4] = 20;  Registers[5] = 3;   Registers[6] = 44;  Registers[7] = 4;
        Registers[8] = 2;   Registers[9] = 1;   Registers[10] = 23; Registers[11] = 4;
        Registers[12] = 90; Registers[13] = 10; Registers[14] = 20; Registers[15] = 30;
        Registers[16] = 40; Registers[17] = 50; Registers[18] = 60; Registers[19] = 70;
        Registers[20] = 80; Registers[21] = 80; Registers[22] = 90; Registers[23] = 70;
        Registers[24] = 60; Registers[25] = 65; Registers[26] = 4;  Registers[27] = 32;
        Registers[28] = 12; Registers[29] = 34; Registers[30] = 5;  Registers[31] = 10;
    end

    assign read_data1 = (Rs1 == 0) ? 32'b0 : Registers[Rs1];
    assign read_data2 = (Rs2 == 0) ? 32'b0 : Registers[Rs2];

endmodule

//............................................Main Control Unit...............................................//
module main_control_unit(
    input [6:0] opcode,          
    output reg RegWrite,         
    output reg MemRead,          
    output reg MemWrite,         
    output reg MemToReg,        
    output reg ALUSrc,                                      
    output reg Branch,                                        
    output reg [1:0] ALUOp       
);

    always @(*) begin
        case (opcode)
            7'b0110011: // R-type 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b10};
            7'b0010011: // I-type
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b10};
            7'b0000011: // Load 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00};
            7'b0100011: // Store 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b00};
            7'b1100011: // Branch 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b11};  
            7'b1101111: // Jump 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b10};
            7'b0110111: // LUI
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b10};
            default: 
                {ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00};  
        endcase
    end

endmodule

//......................................................Immediate Generator..........................//
module immediate_generator(
    input [31:0] instruction,    
    output reg [31:0] imm_out   
);

    always @(*) begin
        case (instruction[6:0]) 
            7'b0010011: imm_out = {{20{instruction[31]}}, instruction[31:20]}; // I-type  
            7'b0000011: imm_out = {{20{instruction[31]}}, instruction[31:20]}; // Load-type
            7'b0100011: imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // Store-type
            7'b1100011: imm_out = {{19{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type 
            7'b0110111: imm_out = {instruction[31:12], 12'b0}; // U-type (LUI)
            7'b0010111: imm_out = {instruction[31:12], 12'b0}; // U-type (AUIPC)
            7'b1101111: imm_out = {{11{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
            default:    imm_out = 32'b0; 
        endcase
    end

endmodule

//.........................................................ALU.............................................//
module ALU(
    input [31:0] A,             
    input [31:0] B,            
    input [3:0] ALUcontrol_In,          
    output reg [31:0] Result,   
    output reg Zero             
);

    always @(*) begin
        case (ALUcontrol_In)
            4'b0000: Result = A + B;                    // ADD
            4'b0001: Result = A - B;                    // SUB
            4'b0010: Result = A & B;                    // AND
            4'b0011: Result = A | B;                    // OR
            4'b0100: Result = A ^ B;                    // XOR
            4'b0101: Result = A << B[4:0];              // SLL
            4'b0110: Result = A >> B[4:0];              // SRL
            4'b0111: Result = $signed(A) >>> B[4:0];     // SRA
            4'b1000: Result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
            default: Result = 32'b0;                  
        endcase
        Zero = (Result == 32'b0) ? 1'b1 : 1'b0;
    end

endmodule

//..............................................ALU Control...................................................//
module ALU_Control(        
    input [2:0] funct3,         
    input [6:0] funct7,        
    input [1:0] ALUOp,          
    output reg [3:0] ALUcontrol_Out 
);
    always @(*) begin
        case ({ALUOp, funct7, funct3})
            12'b10_0000000_000 : ALUcontrol_Out = 4'b0000;    // ADD 
            12'b00_0000000_000 : ALUcontrol_Out = 4'b0000;    // ADD (Loads/Stores)
            12'b00_0000000_001 : ALUcontrol_Out = 4'b0000;    
            12'b00_0000000_010 : ALUcontrol_Out = 4'b0000;    
            12'b10_0100000_000 : ALUcontrol_Out = 4'b0001;    // SUB 
            12'b10_0000000_111 : ALUcontrol_Out = 4'b0010;    // AND
            12'b10_0000000_110 : ALUcontrol_Out = 4'b0011;    // OR
            12'b10_0000000_100 : ALUcontrol_Out = 4'b0100;    // XOR
            12'b10_0000000_001 : ALUcontrol_Out = 4'b0101;    // SLL
            12'b10_0000000_101 : ALUcontrol_Out = 4'b0110;    // SRL
            12'b10_0100000_101 : ALUcontrol_Out = 4'b0111;    // SRA
            12'b10_0000000_010 : ALUcontrol_Out = 4'b1000;    // SLT
            default            : ALUcontrol_Out = 4'b0000; 
        endcase
    end

endmodule

//................................................ALU Mux(2x1)......................................//
module MUX2to1 (
    input [31:0] input0,   
    input [31:0] input1,   
    input select,          
    output [31:0] out      
);

    assign out = (select) ? input1 : input0;  

endmodule

//................................................Data Memory......................................//
module Data_Memory(
    input clk,               
    input rst,               
    input MemRead,           
    input MemWrite,          
    input [31:0] address,    
    input [31:0] write_data, 
    output [31:0] read_data  
);
    reg [31:0] D_Memory [63:0];
    integer k;

    // Shift address right by 2 if addressing words directly from byte addresses
    assign read_data = (MemRead) ? D_Memory[address >> 2] : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 64; k = k + 1) begin
                D_Memory[k] <= 32'b0;
            end
        end else if (MemWrite) begin
            D_Memory[address >> 2] <= write_data;
        end
    end

    // Safely preload default memory values inside an initial block to avoid multi-drivers
    initial begin
        D_Memory[17] = 56;
        D_Memory[15] = 65;
    end

endmodule

//.........................................Data Mem Mux(2x1)....................................//
module MUX2to1_DataMemory (
    input [31:0] input0,  
    input [31:0] input1,  
    input select,         
    output [31:0] out     
);

    assign out = (select) ? input1 : input0; 

endmodule

//.............................................Branch Adder...................................//
module Branch_Adder(
    input [31:0] PC,                    
    input [31:0] offset,                 
    output reg [31:0] branch_target     
);

    always @(*) begin
        branch_target = PC + offset;  
    end

endmodule

//..............................................RISC-V Top.................................//
module RISCV_Top(
    input clk, rst
); 

    // Wire Declarations
    wire [31:0] pc_out_wire, pc_next_wire, pc_wire, decode_wire;
    wire [31:0] read_data1, regtomux, immgen_wire, muxtoAlu, WB_wire;
    wire [31:0] read_data_wire, WB_data_wire, branch_target;
    wire RegWrite, ALUSrc, MemRead, MemWrite, MemToReg, Branch, Zero;
    wire [1:0] ALUOp_wire;
    wire [3:0] ALUcontrol_wire;

    // Submodule Instantiations
    program_counter PC (
        .clk(clk), .rst(rst), .pc_in(pc_wire), .pc_out(pc_out_wire)
    );
    
    pc_adder PC_Adder (
        .pc_in(pc_out_wire), .pc_next(pc_next_wire)
    );
    
    pc_mux pc_mux (
        .pc_in(pc_next_wire), .pc_branch(branch_target), .pc_select(Branch & Zero), .pc_out(pc_wire)
    );
    
    Instruction_Memory Instr_Mem (
        .rst(rst), .clk(clk), .read_address(pc_out_wire), .instruction_out(decode_wire)
    );
    
    Register_File Reg_File (
        .rst(rst), .clk(clk), .RegWrite(RegWrite), 
        .Rs1(decode_wire[19:15]), .Rs2(decode_wire[24:20]), .Rd(decode_wire[11:7]), 
        .Write_data(WB_data_wire), .read_data1(read_data1), .read_data2(regtomux)
    );
    
    main_control_unit Control_Unit (
        .opcode(decode_wire[6:0]), .RegWrite(RegWrite), .MemRead(MemRead), 
        .MemWrite(MemWrite), .MemToReg(MemToReg), .ALUSrc(ALUSrc), .Branch(Branch), .ALUOp(ALUOp_wire)
    );
    
    ALU_Control ALU_Ctrl (
        .funct3(decode_wire[14:12]), .funct7(decode_wire[31:25]), .ALUOp(ALUOp_wire), .ALUcontrol_Out(ALUcontrol_wire)
    );
    
    ALU ALU (
        .A(read_data1), .B(muxtoAlu), .ALUcontrol_In(ALUcontrol_wire), .Result(WB_wire), .Zero(Zero)
    );
    
    immediate_generator Imm_Gen (
        .instruction(decode_wire), .imm_out(immgen_wire)
    );
    
    MUX2to1 Imm_Mux (
        .input0(regtomux), .input1(immgen_wire), .select(ALUSrc), .out(muxtoAlu)
    );
    
    Data_Memory Data_Mem (
        .clk(clk), .rst(rst), .MemRead(MemRead), .MemWrite(MemWrite), 
        .address(WB_wire), .write_data(regtomux), .read_data(read_data_wire)
    );
    
    MUX2to1_DataMemory WB_Mux (
        .input0(WB_wire), .input1(read_data_wire), .select(MemToReg), .out(WB_data_wire)
    );
    
    Branch_Adder B_Adder (
        .PC(pc_out_wire), .offset(immgen_wire), .branch_target(branch_target)
    );

endmodule
