`timescale 1 ns / 1 ps

module write_back // write_back
(
    input  logic clk_i,
    input  logic rstn_i,   
    input  logic [31:0] pc_space, //  space den al    
    input  logic [31:0] instr_space, //space den al
    input  logic [31:0] pc_memory, // memory den al      
    input  logic [31:0] instr_memory, // memory den al
    input  logic reg_file_en_i_space, // space den al   
    input  logic reg_file_en_i_memory, // memorye den al    
    input  logic [31:0] mem_data_adres_i, // memory den al (testbeche yazdırmak için) 
    input  logic [31:0] alu_out_space, // space den al
    input  logic [31:0] alu_out_memory, // memory den al
    input logic [31:0] load_mem_data, // memory den al     // ls_int den alır
    output logic [31:0] load_adres, // memory e adres olarak ver  // ls_int den alır
    output logic [31:0] reg_file_o  [31:0] // decode ver
);

    logic prio;
    logic [31:0] reg_data_space;
    logic [31:0] reg_data_memory;
    logic [31:0] reg_file  [31:0]; 
    logic [31:0] pc_o_space;     //  bunlar ile pc table yaptım, bir yere bağlanmıyor yani
    logic [31:0] instr_o_space;//  bunlar ile pc table yaptım, bir yere bağlanmıyor yani
    logic [31:0] pc_o_memory;     //  bunlar ile pc table yaptım, bir yere bağlanmıyor yani
    logic [31:0] instr_o_memory;//  bunlar ile pc table yaptım, bir yere bağlanmıyor yani
    assign reg_file_o = reg_file; // decode a  direkt gidecek registera gerek yok 
    always_comb  begin  //memory slot icin
        load_adres = 32'b0;
        reg_data_memory = 32'b0;
        if(reg_file_en_i_memory) begin
            load_adres = 32'b0;
            if(instr_memory[6:0] == 7'b1101111 || instr_memory[6:0] == 7'b1100111) begin //JAL, JALR
                reg_data_memory = pc_memory + 4;
            end
            else if(instr_memory[6:0] == 7'b0000011) begin  // LOAD
                load_adres = alu_out_memory;
                case(instr_memory[14:12])
                    3'b000  : begin
                        reg_data_memory = {{24{load_mem_data[7]}}, load_mem_data[7:0]};
                    end 
                    3'b001  : begin
                        reg_data_memory = {{16{load_mem_data[15]}}, load_mem_data[15:0]};
                    end 
                    3'b010  : begin
                        reg_data_memory = load_mem_data;
                    end 
                    3'b100 : begin
                        reg_data_memory = {{24'b0}, load_mem_data[7:0]};
                    end 
                    3'b101 : begin
                        reg_data_memory = {{16'b0}, load_mem_data[15:0]};
                    end  
                    default:    reg_data_memory = 32'b0; 
                endcase       
            end 
            else begin   
                reg_data_memory = alu_out_memory;
            end    
        end  
    end

    always_comb  begin  // branch slot icin
        reg_data_space = 32'b0;
        if(reg_file_en_i_space) begin
            if(instr_space[6:0] == 7'b1101111 || instr_space[6:0] == 7'b1100111) begin //JAL, JALR
                reg_data_space = pc_space + 4;
            end
            else begin   
                reg_data_space = alu_out_space;
            end    
        end  
    end

    always_ff @(negedge clk_i) begin // fall edge yap 
       if (!rstn_i) begin
         for (int i=0; i<32; ++i) begin
           reg_file[i] <= '0;
         end
       end  
       else begin  
            if (reg_file_en_i_memory && instr_memory[11:7] != 5'b0) begin
                reg_file[instr_memory[11:7]] <= reg_data_memory;
            end
            if (reg_file_en_i_space && instr_space[11:7] != 5'b0) begin
                reg_file[instr_space[11:7]] <= reg_data_space;
            end
       end 
    end

    always_ff @(posedge clk_i) begin // pc_table'ye yazdırmak için
       if (rstn_i == 0) begin
            pc_o_space <=32'b0;
            instr_o_space <= 32'b0;
            pc_o_memory <= 32'b0;
            instr_o_memory <= 32'b0;
       end else begin
            pc_o_memory<= pc_memory;
            instr_o_memory <= instr_memory;
            pc_o_space <= pc_space;
            instr_o_space <= instr_space;
       end
    end



endmodule
