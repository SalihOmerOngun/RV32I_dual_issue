`timescale 1 ns / 1 ps

module fetch
  import riscv_pkg::*;
#(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem"       // instruction memory initialization file
)    (
    input  logic clk_i,
    input  logic rstn_i,
    input logic [31:0] alu_out_i, // execute dan al    
    input logic jump_ok,
    input  logic stall_en,
    input  logic stall_issue,
    input  logic stall_issue_handle,
    input  logic flush, // input from hazard unit // new_flush
    output logic update_o, 
    output logic  [31:0] pc_fetch, // decode ver
    output logic  [31:0] pc_fetch_2, // decode ver
    output logic  [31:0] instr_o, // decode ver 
    output logic  [31:0] instr_o_2 // decode ver 
);
    logic [31:0] pc_next;
    logic [31:0] pc_2;
    logic [31:0] jump_pc;
    logic [31:0] instr_1;
    logic [31:0] instr_2;
    logic [31:0] instr_mem [2047:0]; 


    initial begin  
        //$readmemh("D:/SSTU_lab_project/imem.mem", instr_mem, 0, 2047); //Windows için
        $readmemh(IMemInitFile, instr_mem, 0, 2047);
    end   

    always_ff @(posedge clk_i) begin  
       if (rstn_i == 0) begin
            pc_fetch <= 32'h8000_0000;  
            pc_fetch_2 <= 32'h8000_0004;
            update_o <= 0;
       end else begin
            pc_fetch <= pc_next;
            pc_fetch_2 <= pc_2;
            update_o<= 1;
       end
    end
 
    always_comb begin 
        pc_next = pc_fetch;  
        pc_2 = pc_fetch_2;
        if (jump_ok) begin
            pc_next = jump_pc; 
            pc_2 = pc_next + 4;
        end 
        else begin
            if(stall_en == 1 || stall_issue == 1 || stall_issue_handle == 1) begin // hazard için
                pc_next = pc_fetch;  
                pc_2 = pc_next + 4;
            end
            else begin
                pc_next = pc_fetch + 8;
                pc_2 = pc_next + 4;
            end
        end
    end

    assign instr_1 = instr_mem[pc_next[12:2]]; 
    assign instr_2 = instr_mem[pc_2[12:2]]; 

    always_ff @(posedge clk_i) begin // pipelined
       if (rstn_i == 0) begin
            instr_o <= instr_mem[0];
            instr_o_2 <= instr_mem[1];
       end else if(flush == 1) begin
            instr_o <= 32'b0;     
            instr_o_2 <= 32'b0;     
       end else if (stall_issue == 1) begin
            instr_o <= 32'h00000013; // stall_issue geldiyse ilk instrucion ile ikinci instricution ya branch yada load or store. bu durumda ilkini ait oldugu slottan gonderiyorum. diger cycle da ilki nop diğeri bir önceki ikinci instruction oluyor
            instr_o_2 <= instr_o_2; // ikinci aynısı gitmeli o yuzden instr_2 olmadı 
       end else if (!stall_en && stall_issue_handle == 0) begin // eger 1 iseler aynıları gider 
            instr_o <= instr_1; 
            instr_o_2 <= instr_2; 
       end
    end

    always_comb begin 
        if(jump_ok) begin
            jump_pc = alu_out_i;
        end
        else begin
            jump_pc = 32'b0;
        end
    end

endmodule
