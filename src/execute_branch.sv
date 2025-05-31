`timescale 1 ns / 1 ps

module execute_branch // execute
(
    input  logic clk_i,
    input  logic rstn_i,     
    input  logic [31:0] instr, // decode dan al 
    input  logic [31:0] rs1,      // decoden al
    input  logic [31:0] rs2,      // decoden al
    input  logic [31:0] instr_mem_data,      // decoden al
    input  logic [4:0] shamt, // decoden al 
    input  logic [31:0] pc_decode, // decode dan al 
    input  logic [31:0] alu_out_i, // alu dan al
    input logic forw_mem_rs1_en,     // hazard unitten al
    input logic forw_wrtbck_rs1_en,// hazard unitten al
    input logic forw_mem_rs2_en,// hazard unitten al
    input logic forw_wrtbck_rs2_en,  // hazard unitten al  
    input logic forw_mem_rs1_en_mem_to_branch,    // mem to branch olanlar memory slotundan bu slota gidecek veriler
    input logic forw_wrtbck_rs1_en_mem_to_branch,
    input logic forw_mem_rs2_en_mem_to_branch,
    input logic forw_wrtbck_rs2_en_mem_to_branch,     
    input logic [31:0] rs1_hazard, // hazard unitten al
    input logic [31:0] rs2_hazard, // hazard unitten al    
    output logic flush_en, // new_flush
    output logic jump_ok_o ,  // fetch ver *********************************** DİKKAT *****************************
    output logic [31:0] number1, // alu ver 
    output logic [31:0] number2, // alu ver
    output logic [4:0] shamt_data, // alu ver
    output logic  [4:0] sel,  // alu ver
    output logic reg_file_en_o, // data memory ver ------------------> write back
    output logic [31:0] alu_out_o,    // fetch ve data memory ver --------------------------------->  write back  
    output logic [31:0] instr_o, // data memory ver ------------------> write back
    output logic [31:0] pc_o
);
    
    

    logic [31:0] rs1_i;
    logic [31:0] rs2_i;
    logic jump_ok;
    logic reg_file_en;  

    assign flush_en = jump_ok; // flush jump_ok'a combinational bağlı olduğu için fetch'e gidecek olan jump_ok_o göre 1 cycle önce gider

    always_comb begin
        number1 = 32'b0;
        number2 = 32'b0;
        rs1_i = rs1;
        rs2_i = rs2;
        jump_ok = 0;
        reg_file_en = 0;
        if(forw_mem_rs1_en == 1 || forw_mem_rs1_en_mem_to_branch == 1) begin // number1 ve number2 ye direkt atama olmaz rs1 ve rs2 üstünden gitmeli
            rs1_i = rs1_hazard;
        end
        if(forw_wrtbck_rs1_en == 1 || forw_wrtbck_rs1_en_mem_to_branch == 1 ) begin
            rs1_i = rs1_hazard;
        end
        if(forw_mem_rs2_en == 1 || forw_mem_rs2_en_mem_to_branch == 1) begin
            rs2_i = rs2_hazard;
        end
        if(forw_wrtbck_rs2_en == 1 || forw_wrtbck_rs2_en_mem_to_branch == 1) begin
            rs2_i = rs2_hazard;
        end
        case(instr[6:0])
            7'b0110111: begin // LUI
                number1 = instr_mem_data;
                sel = 5'd13;
                reg_file_en = 1; 
            end

            7'b0010111: begin // AUIPC
                number1 = instr_mem_data;
                number2 = pc_decode;
                sel = 5'd0;
                reg_file_en = 1; 
            end

            7'b1101111: begin // JAL  // register file da atamada ozel durum
                jump_ok = 1; 
                number1 = instr_mem_data;
                number2 = pc_decode;
                sel = 5'd0;
                reg_file_en = 1; // hem reg_file_en = 1 hem de jump_ok  = 1  else if olduğu için jump_ok girmez
                // rd ye atama da ozel durum        
            end    

            7'b1100111: begin // JALR // register file da atamada ozel durum
                jump_ok = 1;
                number2 = instr_mem_data;
                number1 = rs1_i;
                sel = 5'd0;
                reg_file_en = 1;
                // rd ye atama da ozel durum       
            end 
            7'b1100011: begin // BRANCH  // beq felan diye ayrı case yapmaya gerk var mı 
                case(instr[14:12]) 
                    3'b000: begin // BEQ
                        if(rs1_i == rs2_i) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0;
                        end        
                    end   
                    3'b001: begin // BNE
                        if(rs1_i != rs2_i) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0; 
                        end    
                    end      
                    3'b100: begin // BLT
                        if ($signed(rs1_i) < $signed(rs2_i)) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0;
                        end    
                    end    
                    3'b101: begin // BGE
                        if ($signed(rs1_i) >= $signed(rs2_i)) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0;
                        end    
                    end    
                    3'b110: begin // BLTU
                        if (rs1_i < rs2_i) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0;
                        end    
                    end    
                    3'b111: begin // BGEU
                        if (rs1_i >= rs2_i) begin
                            jump_ok = 1;
                            number1 = instr_mem_data;
                            number2 = pc_decode;
                            sel = 5'd0;
                        end    
                    end    
                    default : begin
                        number1 = 32'b0;
                        number2 = 32'b0;
                        jump_ok = 0;
                        reg_file_en = 0;
                    end                        
                endcase         
                
            end 

           // 7'b0000011: begin  //  LOAD
           //     case(instr[14:12])
           //         3'b000: begin // LB
           //             number1 = rs1_i;
           //             number2 = instr_mem_data;
           //             reg_file_en = 1; 
           //             sel = 5'd0;
           //         end
           //         3'b001: begin // LH
           //             number1 = rs1_i;
           //             number2 = instr_mem_data;
           //             reg_file_en = 1; 
           //             sel = 5'd0;
           //         end
           //         3'b010: begin // LW
           //             number1 = rs1_i;
           //             number2 = instr_mem_data;
           //             reg_file_en = 1; 
           //             sel = 5'd0;
           //         end
           //         3'b100: begin // LBU
           //             number1 = rs1_i;
           //             number2 = instr_mem_data;
           //             reg_file_en = 1; 
           //             sel = 5'd0;
           //         end
           //         3'b101: begin // LHU
           //             number1 = rs1_i;
           //             number2 = instr_mem_data;
           //             reg_file_en = 1; 
           //             sel = 5'd0;
           //         end
           //         default : begin
           //             number1 = 32'b0;
           //             number2 = 32'b0;
           //             jump_ok = 0;
           //             reg_file_en = 0;
           //         end                     
           //     endcase                  
           // end  

            //7'b0100011: begin // STORE 
            //    case(instr[14:12])
            //        3'b000: begin // SB
            //            mem_data = rs2_i;
            //            number1 = rs1_i;
            //            number2 = instr_mem_data;
            //            mem_en = 1; 
            //            sel = 5'd0;
            //        end
            //        3'b001: begin // SH
            //            mem_en = 1;
            //            mem_data = rs2_i;
            //            number1 = rs1_i;
            //            number2 = instr_mem_data;
            //            sel = 5'd0;
            //        end
            //        3'b010: begin // SW
            //            mem_en = 1;
            //            mem_data = rs2_i;
            //            number1 = rs1_i;
            //            number2 = instr_mem_data;
            //            sel = 5'd0;
            //        end
            //        default : begin
            //            number1 = 32'b0;
            //            number2 = 32'b0;
            //            jump_ok = 0;
            //            reg_file_en = 0;
            //            mem_en = 0;
            //        end                     
            //    endcase                                    
            //end 

            7'b0010011: begin  // IMMEDIATE
                case(instr[14:12])
                    3'b000: begin  //ADDI
                        reg_file_en = 1;
                        number2 =  $signed(instr_mem_data);
                        number1 =  $signed(rs1_i);
                        sel = 5'd0;   
                    end            
                    3'b010: begin //SLTI
                        reg_file_en = 1;
                        if ($signed(rs1_i) < $signed(instr_mem_data)) begin 
                            sel = 5'd12;
                        end
                        else begin
                            sel = 5'd11;
                        end
                    end            
                    3'b011: begin // SLTIU
                        reg_file_en = 1;
                        if (rs1_i < instr_mem_data) begin 
                            sel = 5'd12;
                        end
                        else begin
                            sel = 5'd11;
                        end                        
                    end            
                    3'b100: begin // XORI
                        reg_file_en = 1;
                        number1 = rs1_i;
                        number2 = instr_mem_data;
                        sel = 5'd3;
                    end            
                    3'b110: begin // ORI 
                        reg_file_en = 1;
                        number1 = rs1_i;
                        number2 = instr_mem_data;
                        sel = 5'd2;                        
                    end            
                    3'b111: begin // ANDI 
                        reg_file_en = 1;
                        number1 = rs1_i;
                        number2 = instr_mem_data;
                        sel = 5'd4;                        
                        
                    end      
                    3'b001: begin 
                        if (instr[31:25] == 7'b0000000) begin // SLLI
                            reg_file_en = 1; // reg_file_en 1 almiyor else'e giriyor
                            number1 = rs1_i;
                            shamt_data = shamt;
                            sel = 5'd8; 
                        end    
                        else if (instr[31:25] == 7'b0110000) begin // CLZ CTZ CPOP  
                            case(instr[24:20])
                                5'b00000: begin // CLZ
                                    reg_file_en = 1;
                                    number1 = rs1_i;
                                    sel = 5'd14;
                                end
                                5'b00001: begin // CTZ
                                    reg_file_en = 1;
                                    number1 = rs1_i;
                                    sel = 5'd15;
                                end
                                5'b00010: begin // CPOP
                                    reg_file_en = 1;
                                    number1 = rs1_i;
                                    sel = 5'd16;
                                end   
                                default: begin
                                    number1 = 32'b0;
                                    number2 = 32'b0;
                                    jump_ok = 0;
                                    reg_file_en = 1;
                                end                
                            endcase
                        end    
                        else begin  // if if else yapınca 2. if'i etkiliyor else bloğu ilk if'e girince yine de else'e giriyor
                           number1 = 32'b0;
                           number2 = 32'b0;
                           jump_ok = 0;
                           reg_file_en = 0;
                        end  
                    end      
                    3'b101: begin // SRLI, SRAI 
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1;
                            number1 = rs1_i;
                            shamt_data = shamt;
                            sel = 5'd9; 
                        end else  if (instr[31:25] == 7'b0100000) begin
                            reg_file_en = 1;
                            number1 = rs1_i;
                            shamt_data = shamt;
                            sel = 5'd10; 
                        end                        
                    end      
                endcase      
            end
            7'b0110011: begin // aritmetik ve mantiksal
                case(instr[14:12]) 
                    3'b000 : begin // ADD, SUB
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd0;
                        end 
                        else if (instr[31:25] == 7'b0100000) begin
                            reg_file_en = 1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd1;
                        end
                    end 
                    3'b001 : begin // SLL
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd5;
                        end
                    end 
                    3'b010 : begin // SLT
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1;
                            if ($signed(rs1_i) < $signed(rs2_i)) begin 
                                sel = 5'd12;
                            end
                            else begin
                                sel = 5'd11;
                            end
                        end
                    end
                    3'b011 : begin // SLTU
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1;
                            if (rs1_i < rs2_i) begin 
                                sel = 5'd12;
                            end
                            else begin
                                sel = 5'd11;
                            end
                        end
                    end
                    3'b100 : begin // XOR
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1'b1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd3;
                        end
                    end 
                    3'b101 : begin // SRL, SRA
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1'b1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd6;
                        end 
                        else if (instr[31:25] == 7'b0100000) begin
                            reg_file_en = 1'b1;
                            number1 = $signed(rs1_i);
                            number2 = rs2_i;
                            sel = 5'd7;
                        end
                    end 
                    3'b110  : begin // OR 
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1'b1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd2;
                        end
                    end    
                    3'b111 : begin
                        if (instr[31:25] == 7'b0000000) begin
                            reg_file_en = 1'b1;
                            number1 = rs1_i;
                            number2 = rs2_i;
                            sel = 5'd4;
                        end 
                    end 
                endcase           
            end     
            default : begin
                number1 = 32'b0;
                number2 = 32'b0;
                jump_ok = 0;
                reg_file_en = 0;
            end    
        endcase     
    end  

    always_ff @(posedge clk_i) begin // pipelined
       if (rstn_i == 0) begin
            instr_o <= 32'b0;
            jump_ok_o <= 0;
            reg_file_en_o <= 0;
            alu_out_o <= 32'b0;
            pc_o <= 32'b0;
       end else begin
            pc_o <= pc_decode;
            instr_o <= instr; 
            jump_ok_o <= jump_ok; 
            reg_file_en_o <= reg_file_en;
            alu_out_o <= alu_out_i;
       end
    end
endmodule


 



