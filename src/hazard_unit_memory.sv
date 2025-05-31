`timescale 1 ns / 1 ps

module hazard_unit_memory 
(
    input  logic clk_i,
    input  logic rstn_i, 
    input  logic [31:0] instr_ls_int_iss, // issue deen çıkıp decode_branch e giren instr (stall için lazım)
    input  logic [31:0] instr_bra_int_iss,
    //input  logic [31:0] instr_fetch, // decode a giren instruction
    input  logic [31:0] instr_excte, // data memeory e giren instruction
    input  logic [31:0] instr_excte_branch, // space e giren instruction
    input  logic [31:0] instr_decode, // execute a giren instruction
    input  logic [31:0] instr_decode_branch, // execute_branch a giren instruction
    input  logic [31:0] instr_memory, // write back a giren instruction
    input  logic [31:0] instr_space, // write back a giren instruction
    input  logic [31:0] pc_excte,
    input  logic [31:0] pc_excte_branch,
    input  logic [31:0] pc_memory,
    input  logic [31:0] pc_space,
    //input  flush_en, // input form execute // new_flush
    input  logic  [31:0] alu_out_excte, // memory e giren alu sonucu
    input  logic  [31:0] alu_out_excte_branch, // space e giren alu sonucu
    input  logic  [31:0] alu_out_memory, // write back e giren alu sonucu
    input  logic  [31:0] alu_out_space, // write back e giren alu sonucu
    input  logic hazard_rs1, // decode da rs1 ataması oldu mu 
    input logic  hazard_rs2,// decode da rs2 ataması oldu mu 
    input  logic hazard_rs1_branch, // decode da rs1 ataması oldu mu 
    input logic  hazard_rs2_branch,// decode da rs2 ataması oldu mu 
    input logic [31:0] load_mem_data_hazard, // memory den al    
    output logic [31:0] load_adres_hazard, // memory e adres olarak ver    
    output logic forw_mem_rs1_en,
    //output flush, // output to fetch and decode // new_flush
    output logic forw_wrtbck_rs1_en,
    output logic forw_mem_rs2_en,
    output logic forw_wrtbck_rs2_en,
    output logic stall_en,
    output logic [31:0] rs1_hazard,
    output logic [31:0] rs2_hazard,
    output logic forw_mem_rs1_en_branch_to_mem,    // branch to mem olanlar branch slotundan bu slota gidecek veriler
    output logic forw_wrtbck_rs1_en_branch_to_mem,
    output logic forw_mem_rs2_en_branch_to_mem,
    output logic forw_wrtbck_rs2_en_branch_to_mem
);
        
    assign load_adres_hazard = alu_out_memory; // alu sonucu load da adres belirliyor. o yüzden böyle yaptım.
    
    //assign flush = flush_en;              
                                
    always_comb begin // rs1  icin // burada hazard_rs1'i kontrol etmene gerek yok decode da rs2 ataması yoksa zaten execute da number1'e immediate felan verir, rs1 yada hzard_rs1 vermez
        forw_mem_rs1_en     = 0;
        forw_mem_rs1_en_branch_to_mem = 0;
        forw_wrtbck_rs1_en  = 0;
        forw_wrtbck_rs1_en_branch_to_mem = 0;
        rs1_hazard = 32'b0;
        if (instr_decode[19:15] != 5'b0) begin 
            if(instr_excte[6:0] != 7'b1100011 && instr_excte[6:0] != 7'b0100011 && instr_excte[6:0] != 7'b0000011) begin // store, branch yada load(load ise write backden okumalı) değilse
                if (instr_decode[19:15] == instr_excte[11:7]) begin // execute a giren rs1 adresi ve data memory e giren rd adresi aynı mı 
                    forw_mem_rs1_en = 1; // data memory e giren alu sonucunu execute a giren rs1 e yaz                    
                    if(instr_excte[6:0] == 7'b1101111 || instr_excte[6:0] == 7'b1100111) begin //JAL, JALR // pc+4'ü alu da hesaplamıyor
                        rs1_hazard = pc_excte + 4;
                    end      
                    else begin
                        rs1_hazard = alu_out_excte;
                    end  
                end
            end
            if(instr_excte_branch[6:0] != 7'b1100011 && instr_excte_branch[6:0] != 7'b0100011 && instr_excte_branch[6:0] != 7'b0000011) begin // store, branch yada load(load ise write backden okumalı) değilse
                if (instr_decode[19:15] == instr_excte_branch[11:7]) begin // execute a giren rs1 adresi ve space e giren rd adresi aynı mı 
                    forw_mem_rs1_en_branch_to_mem = 1; // space e giren alu sonucunu execute a giren rs1 e yaz                    
                    if(instr_excte_branch[6:0] == 7'b1101111 || instr_excte_branch[6:0] == 7'b1100111) begin //JAL, JALR // pc+4'ü alu da hesaplamıyor
                        rs1_hazard = pc_excte_branch + 4;
                    end      
                    else begin
                        rs1_hazard = alu_out_excte_branch;
                    end  
                end // bu stage branch slotunda space'e giren instr'ın rd'si ile memory slotunda execute'e giren instr'ın rs1'i aynı ise devreye giriyor. hem memory hem de branch slotunda aynı rd'ye sahip instruction olamaz onu hallettim inşallah issue handler da 
            end
            if(instr_memory[6:0] != 7'b1100011 && instr_memory[6:0] != 7'b0100011) begin // store, branch değilse // else if yapma hem execute dad hem de memory de store ve branch olmayabilir
                if(instr_decode[19:15] == instr_memory[11:7] && forw_mem_rs1_en == 0 && forw_mem_rs1_en_branch_to_mem == 0)begin // execute a giren rs1 adresi ve write back e giren rd adresi aynı mı 
                    forw_wrtbck_rs1_en = 1; // write back e giren alu sonucunu execute a giren rs1 e yaz                    
                    if(instr_memory[6:0] == 7'b1101111 || instr_memory[6:0] == 7'b1100111) begin //JAL, JALR
                        rs1_hazard = pc_memory + 4;
                    end
                    else if(instr_memory[6:0] == 7'b0000011) begin  // LOAD
                        case(instr_memory[14:12])
                            3'b000  : begin
                                rs1_hazard = {{24{load_mem_data_hazard[7]}}, load_mem_data_hazard[7:0]};
                            end 
                            3'b001  : begin
                                rs1_hazard = {{16{load_mem_data_hazard[15]}}, load_mem_data_hazard[15:0]};
                            end 
                            3'b010  : begin
                                rs1_hazard = load_mem_data_hazard;
                            end 
                            3'b100 : begin
                                rs1_hazard = {{24'b0}, load_mem_data_hazard[7:0]};
                            end 
                            3'b101 : begin
                                rs1_hazard = {{16'b0}, load_mem_data_hazard[15:0]};
                            end  
                            default:    rs1_hazard = 32'b0; 
                        endcase   
                    end                      
                    else begin
                        rs1_hazard = alu_out_memory;
                    end  
                end
            end    
            if(instr_space[6:0] != 7'b1100011 && instr_space[6:0] != 7'b0100011) begin // store, branch değilse // else if yapma hem execute dad hem de memory de store ve branch olmayabilir
                if(instr_decode[19:15] == instr_space[11:7] && forw_mem_rs1_en == 0 && forw_mem_rs1_en_branch_to_mem == 0)begin // execute a giren rs1 adresi ve write back e giren rd adresi aynı mı 
                    forw_wrtbck_rs1_en_branch_to_mem = 1; // write back e giren alu sonucunu execute a giren rs1 e yaz                    
                    if(instr_space[6:0] == 7'b1101111 || instr_space[6:0] == 7'b1100111) begin //JAL, JALR
                        rs1_hazard = pc_space + 4;
                    end  // space'de memory bulunmuyor o yüzden load işlemleri çünkü load komutu yok branch slotunda. load için burada özel işleme gerek yok                
                    else begin
                        rs1_hazard = alu_out_space;
                    end  
                end
            end    
        end
    end

    always_comb begin // rs2  icin // burada hazard_rs2'yi kontrol etmene gerek yok decode da rs2 ataması yoksa zaten execute da number2'ye immediate felan verir, rs2 yada hzard_rs2 vermez
        forw_mem_rs2_en = 0;
        forw_mem_rs2_en_branch_to_mem = 0;
        forw_wrtbck_rs2_en = 0;
        forw_wrtbck_rs2_en_branch_to_mem = 0;
        rs2_hazard = 32'b0;
        if (instr_decode[24:20] != 5'b0 ) begin // rs2 oluştuysa
            if(instr_excte[6:0] != 7'b1100011 && instr_excte[6:0] != 7'b0100011 && instr_excte[6:0] != 7'b0000011) begin // store yada branch yada load değilse
                if (instr_decode[24:20] == instr_excte[11:7]) begin // execute a giren rs2 adresi ve data memory e giren rd adresi aynı mı 
                    forw_mem_rs2_en = 1; // data memory e giren alu sonucunu execute a giren rs2 e yaz                    
                    if(instr_excte[6:0] == 7'b1101111 || instr_excte[6:0] == 7'b1100111) begin //JAL, JALR // pc+4'ü alu da hesaplamıyor
                        rs2_hazard = pc_excte + 4;
                    end                       
                    else begin
                        rs2_hazard = alu_out_excte;
                    end  
                end
            end    
            if(instr_excte_branch[6:0] != 7'b1100011 && instr_excte_branch[6:0] != 7'b0100011 && instr_excte_branch[6:0] != 7'b0000011) begin // store yada branch yada load değilse
                if (instr_decode[24:20] == instr_excte_branch[11:7]) begin // execute a giren rs2 adresi ve space e giren rd adresi aynı mı 
                    forw_mem_rs2_en_branch_to_mem = 1; // space e giren alu sonucunu execute a giren rs2 e yaz                    
                    if(instr_excte_branch[6:0] == 7'b1101111 || instr_excte_branch[6:0] == 7'b1100111) begin //JAL, JALR // pc+4'ü alu da hesaplamıyor
                        rs2_hazard = pc_excte_branch + 4;
                    end                       
                    else begin
                        rs2_hazard = alu_out_excte_branch;
                    end  
                end// bu stage branch slotunda space'e giren instr'ın rd'si ile memory slotunda execute'e giren instr'ın rs2'i aynı ise devreye giriyor. hem memory hem de branch slotunda aynı rd'ye sahip instruction olamaz onu hallettim inşallah issue handler da 
            end    
            if(instr_memory[6:0] != 7'b1100011 && instr_memory[6:0] != 7'b0100011) begin
                if(instr_decode[24:20] == instr_memory[11:7] && forw_mem_rs2_en == 0 && forw_mem_rs2_en_branch_to_mem == 0)begin // execute a giren rs2 adresi ve write back e giren rd adresi aynı mı 
                    forw_wrtbck_rs2_en = 1; // write back e giren alu sonucunu execute a giren rs2 e yaz                    
                    if(instr_memory[6:0] == 7'b1101111 || instr_memory[6:0] == 7'b1100111) begin //JAL, JALR
                        rs2_hazard = pc_memory + 4;
                    end 
                    else if(instr_memory[6:0] == 7'b0000011) begin  // LOAD // alu sonucu load da adres belirliyor. o yüzden böyle yaptım.
                        case(instr_memory[14:12])
                            3'b000  : begin
                                rs2_hazard = {{24'({load_mem_data_hazard[7]})}, load_mem_data_hazard[7:0]};
                            end 
                            3'b001  : begin
                                rs2_hazard = {{16'({load_mem_data_hazard[7]})}, load_mem_data_hazard[15:0]};
                            end 
                            3'b010  : begin
                                rs2_hazard = load_mem_data_hazard;
                            end 
                            3'b100 : begin
                                rs2_hazard = {{24'b0}, load_mem_data_hazard[7:0]};
                            end 
                            3'b101 : begin
                                rs2_hazard = {{16'b0}, load_mem_data_hazard[15:0]};
                            end  
                            default:    rs2_hazard = 32'b0; 
                        endcase   
                    end                                         
                    else begin
                        rs2_hazard = alu_out_memory;
                    end
                end
            end    
            if(instr_space[6:0] != 7'b1100011 && instr_space[6:0] != 7'b0100011) begin
                if(instr_decode[24:20] == instr_space[11:7] && forw_mem_rs2_en == 0 && forw_mem_rs2_en_branch_to_mem == 0)begin // execute a giren rs2 adresi ve write back e giren rd adresi aynı mı 
                    forw_wrtbck_rs2_en_branch_to_mem = 1; // write back e giren alu sonucunu execute a giren rs2 e yaz                    
                    if(instr_space[6:0] == 7'b1101111 || instr_space[6:0] == 7'b1100111) begin //JAL, JALR
                        rs2_hazard = pc_space + 4;
                    end                                          
                    else begin
                        rs2_hazard = alu_out_space;
                    end
                end // space'de memory bulunmuyor o yüzden load işlemleri çünkü load komutu yok branch slotunda. load için burada özel işleme gerek yok
            end    
        end
    end

    always_comb begin  // instr_bra_int_iss içinde aynısı always'i tekrar yap
        if(instr_excte[6:0] == 7'b0000011 ) begin // load komutu memory'e gelmiş ( bir cycle geçmiş stall dursun)
            stall_en = 0;
        end   
        else if(instr_decode[6:0] == 7'b0000011) begin // load komutu execute aşamasına gelince stall olmalı 
            if(instr_ls_int_iss[19:15] == instr_decode[11:7] && hazard_rs1 == 1) begin // execute giren komutun rd'si ile decode_memory e giren komutun rs1'i aynı mı. rs1 yerine immediate olursa diye decode da rs1 ataması yaptığım yerlere hazard_rs1 verdim
                stall_en = 1;
            end    
            else if(instr_ls_int_iss[24:20] == instr_decode[11:7] && hazard_rs2 == 1) begin // execute giren komutun rd'si ile decode_memory giren komutun rs2'i aynı mı. rs2 yerine immediate olursa diye decode da rs2 ataması yaptığım yerlere hazard_rs2 verdim
                    stall_en = 1;
            end  
            else if(instr_bra_int_iss[19:15] == instr_decode[11:7] && hazard_rs1_branch == 1) begin // execute giren komutun rd'si ile decode_branch giren komutun rs1'i aynı mı. rs1 yerine immediate olursa diye decode da rs1 ataması yaptığım yerlere hazard_rs1 verdim
                stall_en = 1;
            end    
            else if(instr_bra_int_iss[24:20] == instr_decode[11:7] && hazard_rs2_branch == 1) begin // execute giren komutun rd'si ile decode_branch giren komutun rs2'i aynı mı. rs2 yerine immediate olursa diye decode da rs2 ataması yaptığım yerlere hazard_rs2 verdim
                    stall_en = 1;
            end
            else begin
                stall_en = 0;
            end    
        end
        else begin
            stall_en = 0;
        end     
    end

endmodule
