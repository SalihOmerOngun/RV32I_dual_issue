`timescale 1 ns / 1 ps

module memory // memory
  import riscv_pkg::*;
#(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem"       // instruction memory initialization file
) (
    input  logic clk_i,
    input  logic rstn_i,     
    input  logic [31:0] instr, // execute_memory dan al
    input  logic reg_file_en_i, // execute_memory dan al       
    input  logic [31:0] alu_out_i, // execute_memory dan al
    input  logic [31:0] pc_excte, // execute_memory dan al    
    input  logic mem_en_i, // execute_memory dan al 
    input  logic prio_i, // execute_memoryn dan al
    input  logic [31:0] mem_data_i, // execute_memory den al
    input  logic [31:0] load_adres,    // write back den al
    output logic [31:0] load_mem_data,// write back e ver
    input  logic [31:0] load_adres_hazard, // hazarddan_memory al
    output logic [31:0] load_mem_data_hazard, // hazard_memory a ver
    output logic reg_file_en_o,  // write back ver 
    output logic mem_en_o, // write back ver
    output logic [31:0] mem_data_adres_o,
    output logic [31:0] alu_out_o,    // write back ver  
    output logic [31:0] pc_o, // write back ver
    output logic [31:0] instr_o, // write back ver 
    output logic prio_o// write back ver
);

    logic [31:0] mem_adres;
    logic [31:0] data_mem  [2047:0];

    initial begin  
        //$readmemh("D:/SSTU_lab_project/pipelined.mem", instr_mem, 0, 2047); //Windows için
        //$readmemh(IMemInitFile, instr_mem, 0, 2047);
        $readmemh(DMemInitFile, data_mem, 0, 2047); 
    end   

    always_comb begin 
        if (mem_en_i) begin
            mem_adres = alu_out_i;
        end    
        else begin
            mem_adres = 32'b0;
        end    
    end

    always_comb begin  // read // load komutları için data_mem den okuma yapmak
        load_mem_data = data_mem[load_adres[10:0]];
        load_mem_data_hazard = data_mem[load_adres_hazard[10:0]];
    end


    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            for (int i = 0; i < 2048; i = i + 1) begin
                data_mem[i] <= 0;    
            end    
        end 
        else if (mem_en_i) begin
            if (instr[14:12] == 3'b000) begin  
                data_mem[mem_adres[10:0]][7:0] <= mem_data_i[7:0];  // Byte
            end
            else if (instr[14:12] == 3'b001) begin
                data_mem[mem_adres[10:0]][15:0] <= mem_data_i[15:0];  // Halfword
            end
            else if (instr[14:12] == 3'b010) begin
                data_mem[mem_adres[10:0]] <= mem_data_i;        // Word
            end
       end
    end   

    always_ff @(posedge clk_i) begin // pipelined
       if (rstn_i == 0) begin
            instr_o <= 32'b0;
            reg_file_en_o <= 0;
            alu_out_o <= 32'b0;
            pc_o <= 32'b0;
            mem_en_o <= 0;
            mem_data_adres_o <= 32'b0;
            prio_o <= 0;
       end else begin
            mem_en_o <= mem_en_i;
            mem_data_adres_o <= mem_adres;
            instr_o <= instr;  
            pc_o <= pc_excte;
            reg_file_en_o <= reg_file_en_i;
            alu_out_o <= alu_out_i;  
            prio_o <= prio_i;    
       end
    end


endmodule

