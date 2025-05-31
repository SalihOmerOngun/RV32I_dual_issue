`timescale 1 ns / 1 ps
 // execute dan alacak islem yapmadan verecek. bir slotta memory var digerinde yok. islemcinin in order olması bozulmasın diye bunu eklemek gerekiyor
module space 
(
    input  logic clk_i,
    input  logic rstn_i,     
    input  logic [31:0] instr, // execute dan al
    input  logic reg_file_en_i, // execute dan al       
    input  logic [31:0] alu_out_i, // execute dan al
    input  logic [31:0] pc_excte, // execute dan al    
    output logic reg_file_en_o,  // write back ver 
    output logic [31:0] alu_out_o,    // write back ver  
    output logic [31:0] pc_o, // write back ver
    output logic [31:0] instr_o // write back ver 
);

    always_ff @(posedge clk_i) begin // pipelined
        if (rstn_i == 0) begin
            instr_o <= 32'b0;
            reg_file_en_o <= 0;
            alu_out_o <= 32'b0;
            pc_o <= 32'b0;
        end else begin
            instr_o <= instr;  
            pc_o <= pc_excte;
            reg_file_en_o <= reg_file_en_i;
            alu_out_o <= alu_out_i;          
        end
    end
      
endmodule
