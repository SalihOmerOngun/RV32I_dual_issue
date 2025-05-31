`timescale 1 ns / 1 ps

module core_model
  import riscv_pkg::*;
#(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem",       // instruction memory initialization file
    parameter TableFile     = "table.log",    // processor state and used for verification/grading
    parameter IssueWidth    = 2               // 
)   (
    input  logic             clk_i,                       // system clock
    input  logic             rstn_i,                      // system reset
    input  logic  [XLEN-1:0] addr_i,                      // memory adddres input for reading
    output logic  [XLEN-1:0] data_o,                      // memory data output for reading
    output logic             update_o    [IssueWidth],    // retire signal
    output logic  [XLEN-1:0] pc_o        [IssueWidth],    // retired program counter
    output logic  [XLEN-1:0] instr_o     [IssueWidth],    // retired instruction
    output logic  [     4:0] reg_addr_o  [IssueWidth],    // retired register address
    output logic  [XLEN-1:0] reg_data_o  [IssueWidth],    // retired register data
    output logic  [XLEN-1:0] mem_addr_o  [IssueWidth],    // retired memory address
    output logic  [XLEN-1:0] mem_data_o  [IssueWidth],    // retired memory data
    output logic             mem_wrt_o   [IssueWidth]     // retired memory write enable signal
);
    ///////// fetch 
    logic [31:0] pc_fetch; 
    logic [31:0] instr_fetch;    
    logic [31:0] pc_fetch_2; 
    logic [31:0] instr_fetch_2;    
    ////////
  
    ////////// issue
    logic  [31:0] instr_bra_int_iss; // slotlardaki decode lara ver 
    logic  [31:0] pc_bra_int_iss; // slotlardaki decode lara ver 
    logic  [31:0] instr_ls_int_iss; // slotlardaki decode lara ver 
    logic  [31:0] pc_ls_int_iss; // slotlardaki decode lara ver 
    logic prio_iss; // 2 slot'un da decode stage'ine ver 
    logic stall_issue;
    //////////

    /////////// issue handle
    logic stall_issue_handle;
    logic nop1;
    logic [31:0] instr_ls_int_iss_handle;
    logic [31:0] instr_bra_int_iss_handle;
    ///////////


    ////////// decode_branch
    logic [31:0] pc_decode_branch;
    logic [31:0] instr_decode_branch;         
    logic [31:0] rs1_branch;      
    logic [31:0] rs2_branch;     
    logic [31:0] instr_mem_data_branch; 
    logic [4:0] shamt_branch;     
    logic hazard_rs1_branch;
    logic hazard_rs2_branch;  
    logic prio_decode_branch;
    //////////

    logic [31:0] reg_file_write_back  [31:0];


    ////////// decode_memory
    logic [31:0] pc_decode_memory;
    logic [31:0] instr_decode_memory;         
    logic [31:0] rs1_memory;      
    logic [31:0] rs2_memory;     
    logic [31:0] instr_mem_data_memory; 
    logic [4:0] shamt_memory;     
    logic hazard_rs1_memory;
    logic hazard_rs2_memory;  
    logic prio_decode_memory;    
    logic stall_issue_handle_decode_memory;
    //////////

    ///////// alu_branch
    logic  [31:0] alu_out_alu_branch;
    ////////

    ///////// alu_memory
    logic  [31:0] alu_out_alu_memory;
    ////////

    //////// execute_branch
    logic flush_en_branch;   // sadece branch
    logic jump_ok_excte_branch;   // sadece branch
    logic reg_file_en_excte_branch; 
    logic [31:0] instr_excte_branch;   
    logic [31:0] pc_excte_branch;      
    logic  [31:0] alu_out_excte_branch;
    logic  [4:0] sel_branch; 
    logic  [31:0] number1_branch;    
    logic  [31:0] number2_branch;  
    logic  [4:0] shamt_data_branch;    
    /////////

    //////// execute_memory
    logic reg_file_en_excte_memory; 
    logic [31:0] instr_excte_memory;   
    logic [31:0] pc_excte_memory;      
    logic  [31:0] alu_out_excte_memory;
    logic  [4:0] sel_memory; 
    logic  [31:0] number1_memory;    
    logic  [31:0] number2_memory;  
    logic  [4:0] shamt_data_memory;    
    logic  [31:0] mem_data_excte_memory; // sadece memory
    logic  mem_en_excte_memory; // sadece memory
    logic prio_execute_memory; // sadece memory
    /////////

    ////////// memory
    logic reg_file_en_memory;
    logic mem_en_memory;
    logic [31:0] mem_data_adres_memory;
    logic  [31:0] alu_out_memory;
    logic [31:0] pc_memory; 
    logic [31:0] instr_memory;
    logic prio_memory;
    //////////

    ////////// space
    logic reg_file_en_space;
    logic  [31:0] alu_out_space;
    logic [31:0] pc_space; 
    logic [31:0] instr_space;
    //////////

    /////////// write back to memory or hazard_unit to memory (load komutu için memeory den veri okuma)
    logic [31:0] load_adres;
    logic [31:0] load_mem_data;
    logic [31:0] load_adres_hazard;
    logic [31:0] load_mem_data_hazard;
    ///////////

    //////////// hazard_unit_branch
    logic forw_mem_rs1_en_branch;     
    logic forw_wrtbck_rs1_en_branch;
    logic forw_mem_rs2_en_branch;
    logic forw_wrtbck_rs2_en_branch;  
    logic flush_branch;
    logic [31:0] rs1_hazard_branch; 
    logic [31:0] rs2_hazard_branch; 
    logic forw_mem_rs1_en_mem_to_branch;
    logic forw_wrtbck_rs1_en_mem_to_branch;
    logic forw_mem_rs2_en_mem_to_branch;
    logic forw_wrtbck_rs2_en_mem_to_branch;     
    /////////// 

    //////////// hazard_unit_memory
    logic forw_mem_rs1_en_memory;     
    logic forw_wrtbck_rs1_en_memory;
    logic forw_mem_rs2_en_memory;
    logic forw_wrtbck_rs2_en_memory;  
    logic [31:0] rs1_hazard_memory; 
    logic [31:0] rs2_hazard_memory; 
    logic forw_mem_rs1_en_branch_to_mem;
    logic forw_wrtbck_rs1_en_branch_to_mem;
    logic forw_mem_rs2_en_branch_to_mem;
    logic forw_wrtbck_rs2_en_branch_to_mem;    
    logic stall_en;
    /////////// 



    ///////// table.log için 
    logic stall_issue_handle_fe;
    logic stall_issue_handle_de;
    logic stall_issue_handle_ex;
    logic stall_issue_handle_mem;
    logic stall_issue_handle_wb;
    ////////
    always_ff @(posedge clk_i) begin 
        stall_issue_handle_fe <= stall_issue_handle;
        stall_issue_handle_de <= stall_issue_handle_fe;
        stall_issue_handle_ex <= stall_issue_handle_de;
        stall_issue_handle_mem <= stall_issue_handle_ex;
        stall_issue_handle_wb <= stall_issue_handle_mem;   
    end


/////////////////////  bunlara tekrar ayar yaparsın //////////////////////////////////////
    assign data_o = mem_inst.data_mem[addr_i];    
    assign update_o[1] = fetch_inst.update_o;
    assign mem_data_o[1] = mem_en_memory ? mem_inst.data_mem[mem_data_adres_memory[10:0]] : 32'b0;
    assign mem_addr_o[1]= mem_data_adres_memory; 
    assign mem_wrt_o[1] = mem_en_memory;
    assign mem_data_o[0] = 32'b0;
    assign mem_addr_o[1]= 32'b0; 
    assign mem_wrt_o[0] = 0;
    always_comb begin 
        if(prio_memory == 1) begin // niye böyle anlamadım sor
            pc_o[0] = pc_space;
            pc_o[1] = pc_memory;
            instr_o[0] = instr_space;
            instr_o[1] = instr_memory;
            reg_addr_o[0] = reg_file_en_space ? instr_space[11:7] : 5'b0;
            reg_addr_o[1] = reg_file_en_memory ? instr_memory[11:7] : 5'b0;
            reg_data_o[0] = wrt_bck_inst.reg_data_space; 
            reg_data_o[1] = wrt_bck_inst.reg_data_memory;      
        end
        else if(prio_memory == 0) begin
            pc_o[1] = pc_space;
            pc_o[0] = pc_memory;
            instr_o[1] = instr_space;
            instr_o[0] = instr_memory;
            reg_addr_o[1] = reg_file_en_space ? instr_space[11:7] : 5'b0;
            reg_addr_o[0] = reg_file_en_memory ? instr_memory[11:7] : 5'b0;
            reg_data_o[1] = wrt_bck_inst.reg_data_space; 
            reg_data_o[0] = wrt_bck_inst.reg_data_memory;                  
        end
    end                         
    //assign instr_o_memory = instr_memory;
    //assign instr_o_branch = instr_space;
    //assign reg_addr_o_memory = reg_file_en_memory ? instr_memory[11:7] : 5'b0;
    //assign reg_addr_o_branch = reg_file_en_space ? instr_space[11:7] : 5'b0;
    //assign reg_data_o_memory = wrt_bck_inst.reg_data_memory; 
    //assign reg_data_o_branch = wrt_bck_inst.reg_data_space; 
    //assign mem_data_o = mem_en_memory ? mem_inst.data_mem[mem_data_adres_memory[10:0]] : 32'b0;
    //assign mem_addr_o = mem_data_adres_memory; 
    //assign mem_wrt_o = mem_en_memory;
    //assign pc_o_memory = pc_memory; 
    //assign pc_o_branch = pc_space; 

//////////////////////////////////////////////////////////////////////////////////////////
    


/////////////////////////////////////////////////////////////////  instantiations ///////////////////////////////////////////////////////
    fetch 
    #(
        .DMemInitFile(DMemInitFile),
        .IMemInitFile(IMemInitFile)
    ) fetch_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .alu_out_i(alu_out_excte_branch),  // input form execute_branch        
        .update_o(update_o[0]),  // porta bağlı    
        .jump_ok(jump_ok_excte_branch),   // input from execute_branch                  
        .flush(flush_branch),  // input from hazard_unit_branch                               
        .stall_en(stall_en),  // input from hazard_unit_memory                              
        .stall_issue(stall_issue), // input from issue
        .stall_issue_handle(stall_issue_handle), // input from issue handle
        .pc_fetch(pc_fetch), // output to issue     
        .instr_o(instr_fetch), // output to issue      
        .pc_fetch_2(pc_fetch_2), // output to issue     
        .instr_o_2(instr_fetch_2) // output to issue      
    );   


    issue iss_inst
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .instr_i_1(instr_fetch), // input from fetch
        .pc_1(pc_fetch), // input from fetch
        .instr_i_2(instr_fetch_2), // input from fetch
        .pc_2(pc_fetch_2), // input from fetch
        .flush(flush_branch), // input from hazard_unit_branch 
        .stall_issue_handle(stall_issue_handle), // input from issue handle
        .nop(nop1), // input from issue handle
        .stall_en(stall_en), // input from hazard_unit_memory 
        .stall_issue(stall_issue), // output 
        .instr_bra_int_o(instr_bra_int_iss), // slotlardaki decode lara ver 
        .pc_bra_int_o(pc_bra_int_iss), // slotlardaki decode lara ver 
        .instr_ls_int_o(instr_ls_int_iss), // slotlardaki decode lara ver 
        .pc_ls_int_o(pc_ls_int_iss),    // slotlardaki decode lara ver         
        .prio_o(prio_iss) // output to issue_handle
    );

    issue_handle iss_hand_inst
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .hazard_rs1_bra_int(hazard_rs1_branch), // input from decode_branch
        .hazard_rs2_bra_int(hazard_rs2_branch), // input from decode_branch
        .hazard_rs1_ls_int(hazard_rs1_memory),  // input from decode_memory
        .hazard_rs2_ls_int(hazard_rs2_memory),  // input from decode_memory
        .instr_bra_int(instr_bra_int_iss), // input from issue
        .instr_ls_int(instr_ls_int_iss), // input from issue
        .prio_iss(prio_iss), // input from issue
        .stall_issue_handle(stall_issue_handle), // output
        .nop(nop1), // output
        .instr_ls_int_o(instr_ls_int_iss_handle), // output decode_memory
        .instr_bra_int_o(instr_bra_int_iss_handle) // output decode_memory
    );



    decode_branch dec_bra_inst
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .reg_file(reg_file_write_back), // input from execute
        .instr_i(instr_bra_int_iss), // input form issue 
        .pc_issue(pc_bra_int_iss), // input form issue
        .stall_en(stall_en),     // input from hazard_unit_memory                
        .flush(flush_branch),    // input from hazard_unit_branch   
        .prio_i(prio_iss),     // input from issue   
        .stall_issue_handle(stall_issue_handle),  // input from issue_handle                    
        .instr_issue_handler(instr_bra_int_iss_handle), // input from issue_handle
        .rs1_o(rs1_branch),  // output to execute_branch              
        .rs2_o(rs2_branch), // output to execute_branch               
        .shamt_o(shamt_branch), // output to execute_branch
        .pc_o(pc_decode_branch), // output to execute_branch
        .instr_o(instr_decode_branch), // output to execute_branch
        .hazard_rs1(hazard_rs1_branch), // output to hazard_unit
        .hazard_rs2(hazard_rs2_branch), // output to hazard_unit
        .instr_mem_data_o(instr_mem_data_branch), // output to execute_branch
        .prio_o(prio_decode_branch) // bir yere gitmiyor
    );

   decode_memory dec_mem_inst
   (
       .clk_i(clk_i),
       .rstn_i(rstn_i),
       .reg_file(reg_file_write_back), // input from write back
       .instr_i(instr_ls_int_iss), // input form issue 
       .pc_issue(pc_ls_int_iss), // input form issue 
       .stall_en(stall_en),     // input from hazard_unit_memory                  
       .flush(flush_branch),      // input from hazard_unit_branch
       .prio_i(prio_iss),         // input from issue                     
       .stall_issue_handle(stall_issue_handle), // input from issue_handle
       .instr_issue_handler(instr_ls_int_iss_handle), // input from issue handle
       .rs1_o(rs1_memory),  // output to execute_memory              
       .rs2_o(rs2_memory), // output to execute_memory               
       .shamt_o(shamt_memory), // output to execute_memory
       .pc_o(pc_decode_memory), // output to execute_memory
       .instr_o(instr_decode_memory), // output to execute_memory
       .hazard_rs1(hazard_rs1_memory), // output to hazard_unit
       .hazard_rs2(hazard_rs2_memory), // output to hazard_unit
       .instr_mem_data_o(instr_mem_data_memory), // output to execute
       .prio_o(prio_decode_memory) // output to execute_memory for testbench
   );


    execute_branch exct_bra_int 
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),        
        .instr(instr_decode_branch), // input from decode_branch
        .rs1(rs1_branch), // input from decode_branch
        .rs2(rs2_branch), // input from decode_branch
        .instr_mem_data(instr_mem_data_branch), // input from decode_branch
        .shamt(shamt_branch), // input from decode_branch
        .pc_decode(pc_decode_branch), // input from decode_branch
        .alu_out_i(alu_out_alu_branch), // input from alu_branch 
        .flush_en(flush_en_branch),    // output to hazard_uint                                    
        .forw_mem_rs1_en(forw_mem_rs1_en_branch),     //input from hazard_unit_branch         
        .forw_wrtbck_rs1_en(forw_wrtbck_rs1_en_branch),//input from hazard_unit_branch        
        .forw_mem_rs2_en(forw_mem_rs2_en_branch),//input from hazard_unit_branch              
        .forw_wrtbck_rs2_en(forw_wrtbck_rs2_en_branch),  //input from hazard_unit_branch         
        .forw_mem_rs1_en_mem_to_branch(forw_mem_rs1_en_mem_to_branch), //input from hazard_unit_branch 
        .forw_wrtbck_rs1_en_mem_to_branch(forw_wrtbck_rs1_en_mem_to_branch), //input from hazard_unit_branch 
        .forw_mem_rs2_en_mem_to_branch(forw_mem_rs2_en_mem_to_branch), //input from hazard_unit_branch 
        .forw_wrtbck_rs2_en_mem_to_branch(forw_wrtbck_rs2_en_mem_to_branch), //input from hazard_unit_branch 
        .rs1_hazard(rs1_hazard_branch), //input from hazard_unit_branch                       
        .rs2_hazard(rs2_hazard_branch), //input from hazard_unit_branch                    
        .jump_ok_o(jump_ok_excte_branch), // output to fetch
        .number1(number1_branch), // output to alu_branch
        .number2(number2_branch), // output to alu_branch
        .shamt_data(shamt_data_branch), // output to alu_branch
        .sel(sel_branch), // output to alu_branch
        .reg_file_en_o(reg_file_en_excte_branch), // output to data memory
        .alu_out_o(alu_out_excte_branch), // output to fetch and data emmory 
        .instr_o(instr_excte_branch), // output to data memory
        .pc_o(pc_excte_branch) // output to data memory 
    );

    execute_memory execute_ls_int  
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),        
        .instr(instr_decode_memory), // input from decode_memory
        .rs1(rs1_memory), // input from decode_memory
        .rs2(rs2_memory), // input from decode_memory
        .instr_mem_data(instr_mem_data_memory), // input from decode_memory
        .shamt(shamt_memory), // input from decode_memory
        .pc_decode(pc_decode_memory), // input from decode_memory
        .alu_out_i(alu_out_alu_memory), // input from alu_memory                                 
        .forw_mem_rs1_en(forw_mem_rs1_en_memory),     // input from hazard_unit_memory         
        .forw_wrtbck_rs1_en(forw_wrtbck_rs1_en_memory),// input from hazard_unit_memory        
        .forw_mem_rs2_en(forw_mem_rs2_en_memory),// input from hazard_unit_memory             
        .forw_wrtbck_rs2_en(forw_wrtbck_rs2_en_memory),  // input from hazard_unit_memory         
        .forw_mem_rs1_en_branch_to_mem(forw_mem_rs1_en_branch_to_mem), // input from hazard_unit_memory 
        .forw_wrtbck_rs1_en_branch_to_mem(forw_wrtbck_rs1_en_branch_to_mem), // input from hazard_unit_memory 
        .forw_mem_rs2_en_branch_to_mem(forw_mem_rs2_en_branch_to_mem), // input from hazard_unit_memory 
        .forw_wrtbck_rs2_en_branch_to_mem(forw_wrtbck_rs2_en_branch_to_mem),   // input from hazard_unit_memory       
        .rs1_hazard(rs1_hazard_memory), // input from hazard_unit_memory                       
        .rs2_hazard(rs2_hazard_memory), // input from hazard_unit_memory                       
        .flush(flush_branch), // input from hazard_unit_branch
        .prio_i(prio_decode_memory), // input from decode_memory
        .number1(number1_memory), // output to alu_memory
        .number2(number2_memory), // output to alu_memory
        .shamt_data(shamt_data_memory), // output to alu_memory
        .sel(sel_memory), // output to alu_memory
        .mem_data_o(mem_data_excte_memory), // output to data memory
        .reg_file_en_o(reg_file_en_excte_memory), // output to data memory
        .alu_out_o(alu_out_excte_memory), // output to data emmory 
        .instr_o(instr_excte_memory), // output to data memory
        .pc_o(pc_excte_memory), // output to data memory 
        .mem_en_o(mem_en_excte_memory), // output to data memory
        .prio_o(prio_execute_memory) // output to data memory for testbench
    );

    alu_branch alu_bra_int
    (
        .number1(number1_branch),// input from execute_bracnh
        .number2(number2_branch),// input from execute_bracnh
        .shamt_data(shamt_data_branch),// input from execute_bracnh
        .sel(sel_branch),// input from execute_bracnh
        .alu_out(alu_out_alu_branch) // output to execute_bracnh
    );

    alu_memory alu_ls_int
    (
        .number1(number1_memory),// input from execute_memory
        .number2(number2_memory),// input from execute_memory
        .shamt_data(shamt_data_memory),// input from execute_memory
        .sel(sel_memory),// input from execute_memory
        .alu_out(alu_out_alu_memory) // output to execute_memory
    );
    

    hazard_unit_branch hazard_bra_int
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .instr_excte(instr_excte_branch),// input from execute_branch
        .instr_excte_memory(instr_excte_memory), // input from execte_memory
        //.instr_fetch(instr_fetch),
        .hazard_rs2(hazard_rs2_branch), //  input from decode_branch
        .hazard_rs1(hazard_rs1_branch), // input from decode_branch
        .hazard_rs1_memory(hazard_rs1_memory), // input from decode_memory
        .hazard_rs2_memory(hazard_rs2_memory), // input from decode_memory
        .pc_excte(pc_excte_branch), // input from execute_branch
        .pc_excte_memory(pc_excte_memory), // input from execute_memory
        .pc_space(pc_space), // input from space
        .pc_memory(pc_memory), // input from data memory
        .instr_decode(instr_decode_branch), // input from decode_branch
        .instr_decode_memory(instr_decode_memory), // input from decode_memory
        .instr_space(instr_space), // input from space
        .instr_memory(instr_memory), // input from data memory
        .alu_out_excte(alu_out_excte_branch), // input from execute_branch
        .alu_out_excte_memory(alu_out_excte_memory), // input from execute_memory
        .alu_out_space(alu_out_space),  // input from space
        .alu_out_memory(alu_out_memory), // input from memory
        .flush_en(flush_en_branch), // input from execute_branch
        .flush(flush_branch), // output
        .load_mem_data_hazard(load_mem_data_hazard),// input from data_memory
        .load_adres_hazard(load_adres_hazard), // output to data memory
        .forw_mem_rs1_en(forw_mem_rs1_en_branch),  //output to execute_branch
        .forw_wrtbck_rs1_en(forw_wrtbck_rs1_en_branch), //output to execute_branch
        .forw_mem_rs2_en(forw_mem_rs2_en_branch), //output to execute_branch
        .forw_wrtbck_rs2_en(forw_wrtbck_rs2_en_branch), //output to execute_branch
        .rs1_hazard(rs1_hazard_branch),  //output to execute_branch
        .rs2_hazard(rs2_hazard_branch), //output to execute_branch
        .forw_mem_rs1_en_mem_to_branch(forw_mem_rs1_en_mem_to_branch), //output to execute_branch
        .forw_wrtbck_rs1_en_mem_to_branch(forw_wrtbck_rs1_en_mem_to_branch), //output to execute_branch
        .forw_mem_rs2_en_mem_to_branch(forw_mem_rs2_en_mem_to_branch), //output to execute_branch
        .forw_wrtbck_rs2_en_mem_to_branch(forw_wrtbck_rs2_en_mem_to_branch) //output to execute_branch

    );

    hazard_unit_memory hazard_ls_int
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .instr_excte(instr_excte_memory),
        .instr_excte_branch(instr_excte_branch),
        .instr_ls_int_iss(instr_ls_int_iss),
        .instr_bra_int_iss(instr_bra_int_iss),
        //.instr_fetch(instr_fetch_2),
        .hazard_rs1(hazard_rs1_memory),
        .hazard_rs2(hazard_rs2_memory),
        .hazard_rs1_branch(hazard_rs1_branch),
        .hazard_rs2_branch(hazard_rs2_branch),
        .pc_excte(pc_excte_memory),
        .pc_excte_branch(pc_excte_branch),
        .pc_memory(pc_memory),
        .pc_space(pc_space),
        .load_mem_data_hazard(load_mem_data_hazard),
        .load_adres_hazard(load_adres_hazard),
        .instr_decode(instr_decode_memory),
        .instr_decode_branch(instr_decode_branch),
        .instr_memory(instr_memory),
        .instr_space(instr_space),
        .alu_out_excte(alu_out_excte_memory),
        .alu_out_excte_branch(alu_out_excte_branch),
        .alu_out_memory(alu_out_memory),
        .alu_out_space(alu_out_space),
        .forw_mem_rs1_en(forw_mem_rs1_en_memory),     
        .forw_wrtbck_rs1_en(forw_wrtbck_rs1_en_memory),
        .forw_mem_rs2_en(forw_mem_rs2_en_memory),
        .forw_wrtbck_rs2_en(forw_wrtbck_rs2_en_memory),
        .stall_en(stall_en),  
        .rs1_hazard(rs1_hazard_memory), 
        .rs2_hazard(rs2_hazard_memory),
        .forw_mem_rs1_en_branch_to_mem(forw_mem_rs1_en_branch_to_mem),
        .forw_wrtbck_rs1_en_branch_to_mem(forw_wrtbck_rs1_en_branch_to_mem),
        .forw_mem_rs2_en_branch_to_mem(forw_mem_rs2_en_branch_to_mem),
        .forw_wrtbck_rs2_en_branch_to_mem(forw_wrtbck_rs2_en_branch_to_mem)
    );

    space space_inst
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),        
        .instr(instr_excte_branch),
        .reg_file_en_i(reg_file_en_excte_branch),
        .alu_out_i(alu_out_excte_branch),
        .pc_excte(pc_excte_branch),
        .reg_file_en_o(reg_file_en_space),
        .alu_out_o(alu_out_space),
        .pc_o(pc_space),
        .instr_o(instr_space)
    );


    memory    
    #(
        .DMemInitFile(DMemInitFile),
        .IMemInitFile(IMemInitFile)
    ) mem_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .instr(instr_excte_memory), // input from execute
        .reg_file_en_i(reg_file_en_excte_memory), // input from execute
        .alu_out_i(alu_out_excte_memory), // input from execute
        .load_mem_data(load_mem_data),
        .load_adres(load_adres),
        .load_mem_data_hazard(load_mem_data_hazard),
        .load_adres_hazard(load_adres_hazard),        
        .pc_excte(pc_excte_memory),  // input from execute
        .mem_en_i(mem_en_excte_memory), // input from execute
        .prio_i(prio_execute_memory), // input from execute
        .mem_data_i(mem_data_excte_memory), // input from execute
        .reg_file_en_o(reg_file_en_memory), // output to write back
        .mem_en_o(mem_en_memory),
        .mem_data_adres_o(mem_data_adres_memory),
        .alu_out_o(alu_out_memory), // output to write back
        .pc_o(pc_memory), // output to write back
        .instr_o(instr_memory), // output to write back
        .prio_o(prio_memory)
    );


    write_back  wrt_bck_inst
    (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .pc_memory(pc_memory), // input from memory
        .instr_memory(instr_memory), // input from memory
        .pc_space(pc_space),
        .instr_space(instr_space),
        .load_mem_data(load_mem_data),
        .load_adres(load_adres),
        .reg_file_en_i_memory(reg_file_en_memory), // input from memory
        .reg_file_en_i_space(reg_file_en_space), 
        .mem_data_adres_i(mem_data_adres_memory),
        .alu_out_memory(alu_out_memory), // input from memory
        .alu_out_space(alu_out_space),
        .reg_file_o(reg_file_write_back) // output to decode
    );
endmodule
