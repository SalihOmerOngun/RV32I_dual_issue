`timescale 1 ns / 1 ps

//bu stage de instructionlar sornaki stageler icin memory yada branch slotlarına gonderiliyor   
module issue 
(
    input  logic clk_i,
    input  logic rstn_i,
    input  logic  [31:0] instr_i_1,         // fetch den al
    input  logic  [31:0] pc_1,    // fetch den al
    input  logic  [31:0] instr_i_2,         // fetch den al
    input  logic  [31:0] pc_2,   // fetch den al
    input  logic  flush,
    input  logic  stall_issue_handle,
    input  logic  nop,
    input  logic  stall_en,
    output logic  stall_issue,
    output logic  [31:0] instr_bra_int_o, // slotlardaki decode lara ver 
    output logic  [31:0] pc_bra_int_o, // slotlardaki decode lara ver 
    output logic  [31:0] instr_ls_int_o, // slotlardaki decode lara ver 
    output logic  [31:0] pc_ls_int_o, // slotlardaki decode lara ver 
    output logic prio_o // 2 slot'un da decode stag'ine ver 
);
    logic prio; // 0 ise bra_int priority, 1 ise ls_int priority
    logic same_instr;
    logic  [31:0] instr_bra_int;
    logic  [31:0] pc_bra_int;
    logic  [31:0] instr_ls_int;
    logic  [31:0] pc_ls_int;
    assign stall_issue = same_instr;

    always_comb begin 
        same_instr = 0; // ayni mi diye instr_1 üstünden bakıyoruz
        if (instr_i_1[6:0] == 7'b1100011 ||instr_i_1[6:0] == 7'b1101111 || instr_i_1[6:0] == 7'b1100111) begin // ilk instruction branch jal jalr
            instr_bra_int = instr_i_1;
            pc_bra_int = pc_1;
            prio = 0;
            if(instr_i_2[6:0] == 7'b1100011 ||instr_i_2[6:0] == 7'b1101111 || instr_i_2[6:0] == 7'b1100111) begin  // ikinci instrcution da branch jal jalr olması lazım
                same_instr = 1; // fetch stall et
                instr_ls_int = 32'h00000013; // nop 
                pc_ls_int = pc_2;
            end
            else begin // ikinci instruction branch degil memory slot'u kullanilabilir
                instr_ls_int = instr_i_2;
                pc_ls_int = pc_2;
            end
        end 
        else if (instr_i_1[6:0] == 7'b0000011 || instr_i_1[6:0] == 7'b0100011) begin // ilk instruction load or store
            instr_ls_int = instr_i_1;
            pc_ls_int = pc_1;
            prio = 1;
            if(instr_i_2[6:0] == 7'b0000011 || instr_i_2[6:0] == 7'b0100011) begin  // ikinci instrcution da load or store stall olması lazım
                same_instr = 1;
                instr_bra_int = 32'h00000013; // nop 
                pc_bra_int = pc_2;
            end
            else begin // ikinci instruction load or store degil branch slot'u kullanilabilir
                instr_bra_int = instr_i_2;
                pc_bra_int = pc_2;
            end
        end
        else begin // ilk instruction integer yani tüm slotlara girebilir ikinci instructiona bakmak lazim
            if (instr_i_2[6:0] == 7'b1100011 ||instr_i_2[6:0] == 7'b1101111 || instr_i_2[6:0] == 7'b1100111) begin // ikinci instruction branch jal jalr
                instr_bra_int = instr_i_2;
                pc_bra_int = pc_2;
                instr_ls_int = instr_i_1;
                pc_ls_int = pc_1;
                prio = 1;
            end 
            else if (instr_i_2[6:0] == 7'b0000011 || instr_i_2[6:0] == 7'b0100011) begin // ikinci instruction load or store
                instr_ls_int = instr_i_2;
                pc_ls_int = pc_2;
                instr_bra_int = instr_i_1;
                pc_bra_int = pc_1;
                prio = 0;
            end     
            else begin // ikiside integer islemler
                instr_bra_int = instr_i_1; // ilki branchta 
                pc_bra_int = pc_1;
                instr_ls_int = instr_i_2; // ikinci ls de 
                pc_ls_int = pc_2;
                prio = 0;
            end           

        end 
    end


    always_ff @(posedge clk_i) begin // pipelined
        if (rstn_i == 0) begin
            instr_bra_int_o <= 32'b0;
            pc_bra_int_o <= 32'b0;
            instr_ls_int_o <= 32'b0;
            pc_ls_int_o  <= 32'b0 ;
            prio_o <= 0;
        end else if(flush == 1) begin
            instr_bra_int_o <= 32'b0;
            pc_bra_int_o <= pc_bra_int;
            instr_ls_int_o <= 32'b0;
            pc_ls_int_o  <= pc_ls_int;
            prio_o <= 0;    
        end else if(stall_issue_handle == 1) begin
            if(nop == 0) begin // branch nop edildi decode da buradan branch tekrar gitmeli digeri nop olmalı 
                instr_bra_int_o <= instr_bra_int_o;
                pc_bra_int_o <= pc_bra_int_o; // pc lere dokunmadım
                instr_ls_int_o <= 32'h00000000;
                pc_ls_int_o <= pc_ls_int_o; // pc lere dokunmadım
                prio_o <= prio; 
            end    
            else begin // ls nop edildi decode da buradan tekrar ls gitmeli digeri nop olmalı 
                instr_bra_int_o <= 32'h00000000;
                pc_bra_int_o <= pc_bra_int_o; // pc lere dokunmadım
                instr_ls_int_o <= instr_ls_int_o;
                pc_ls_int_o <= pc_ls_int_o; // pc lere dokunmadım
                prio_o <= prio;                 
            end
        end else if(stall_en == 0) begin
            instr_bra_int_o <= instr_bra_int;
            pc_bra_int_o <= pc_bra_int; 
            instr_ls_int_o <= instr_ls_int;
            pc_ls_int_o <= pc_ls_int; 
            prio_o <= prio;             
        end
    end

endmodule
