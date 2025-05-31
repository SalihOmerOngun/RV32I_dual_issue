`timescale 1 ns / 1 ps
    // bu stage da paralel instructionlar arası herhangi bir hazard var mı diye bakılıyor. varsa decode slotları tekrar düzenleniyor
module issue_handle 
(
    input  logic clk_i,
    input  logic rstn_i,  
    input logic hazard_rs1_bra_int,  // branch slot decode dan al 
    input logic hazard_rs2_bra_int,  // branch slot decode dan al 
    input logic [31:0] instr_bra_int, // issue den al
    input logic hazard_rs1_ls_int,  // memory slot decode dan al 
    input logic hazard_rs2_ls_int, // memory slot decode dan al 
    input logic [31:0] instr_ls_int, // issue den al
    input logic prio_iss, // issue çıkışından al
    output logic stall_issue_handle, // decode a gonder 
    output logic nop,
    output logic [31:0] instr_ls_int_o,  // decode lara gonder
    output logic [31:0] instr_bra_int_o // decode lara gonder
);
    // hazard detect olursa rs olan yer normal olarak gitsin decode a . diger slot nop vermeli decode da   OK 
    // issue ya buradan nop gonderilen instruction'ı gonder obur cycle da o gitsin, diger slottan(bir onceki cycle da normal gidenden) nop gonder  OK
    // pc stall yap   OK 

    // hazard_rs1 ve hazard_rs2  zaten issue dan instr girince combinational olarak hemen değer alıyorlar, sen decode cıkısını buraya verirsen isntruction zaten çoktan execute gitmiş olacak geç olacak. 
    always_comb begin 
        stall_issue_handle = 0;
        nop = 0;
        instr_bra_int_o = 32'b0;
        instr_ls_int_o = 32'b0;
        if(prio_iss == 0 && instr_bra_int[11:7] != 5'b0 ) begin //bra_int oncelikli ise ve rd x0 degilse
            if (instr_bra_int[6:0] != 7'b1100011 && instr_bra_int[6:0] != 7'b0100011) begin //  bra_int'de rd varsa
                if(instr_bra_int[11:7] == instr_ls_int[19:15] && hazard_rs1_ls_int == 1) begin  // branch slotun rd'si ile  ls slotun rs1'i aynı RAW HAZARD
                    stall_issue_handle = 1;
                    instr_bra_int_o = instr_bra_int;
                    instr_ls_int_o = 32'h00000000;
                    nop = 1; // ls slotunda nop var 
                end 
                else if(instr_bra_int[11:7] == instr_ls_int[24:20] && hazard_rs2_ls_int == 1) begin  // branch slotun rd'si ile  ls slotun rs2'si aynı RAW HAZARD
                    stall_issue_handle = 1;
                    instr_bra_int_o = instr_bra_int;
                    instr_ls_int_o = 32'h00000000;
                    nop = 1; // ls slotunda nop var 
                end             
                else if(instr_bra_int[11:7] == instr_ls_int[11:7] && instr_ls_int[6:0] != 7'b1100011 && instr_ls_int[6:0] != 7'b0100011 ) begin  // branch slotun rd'si ile  ls slotun rd'si aynı ise ve ls_int de rd varsa WAW HAZARD
                    stall_issue_handle = 1;
                    instr_bra_int_o = instr_bra_int;
                    instr_ls_int_o = 32'h00000000;
                    nop = 1; // ls slotunda nop var 
                end             
            end
        end
        else if(prio_iss == 1 && instr_ls_int[11:7] != 5'b0 ) begin  // ls_int oncelikli ise ve rd x0 degilse
            if(instr_ls_int[6:0] != 7'b1100011 && instr_ls_int[6:0] != 7'b0100011 && instr_ls_int[11:7] != 5'b0) begin // ls_int de rd varsa ve rd x0 degilse
                if(instr_ls_int[11:7] == instr_bra_int[19:15] && hazard_rs1_bra_int == 1) begin  // ls slotun rd'si ile branch slotun rs1'i aynı RAW HAZARD
                    stall_issue_handle = 1;
                    instr_ls_int_o = instr_ls_int;
                    instr_bra_int_o = 32'h00000000;
                    nop = 0; // branch slotunda nop var 
                end 
                else if(instr_ls_int[11:7] == instr_bra_int[24:20] && hazard_rs2_bra_int == 1) begin  // ls slotun rd'si ile bra slotun rs2'si aynı RAW HAZARD
                    stall_issue_handle = 1;
                    instr_ls_int_o = instr_ls_int;
                    instr_bra_int_o = 32'h00000000;
                    nop = 0; // branch slotunda nop var 
                end             
                else if(instr_ls_int[11:7] == instr_bra_int[11:7] && instr_bra_int[6:0] != 7'b1100011 && instr_bra_int[6:0] != 7'b0100011) begin  // branch slotun rd'si ile  ls slotun rd'si aynı WAW HAZARD ve bra_int de rd varsa
                    stall_issue_handle = 1;
                    instr_ls_int_o = instr_ls_int;
                    instr_bra_int_o = 32'h00000000;
                    nop = 0; // branch slotunda nop var 
                end              
            end
        end
    end
endmodule
