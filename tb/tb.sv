module tb ();
  parameter int IssueWidth = 2;
  logic [riscv_pkg::XLEN-1:0] addr;
  logic [riscv_pkg::XLEN-1:0] data;
  logic [riscv_pkg::XLEN-1:0] pc [IssueWidth-1:0];
  logic [riscv_pkg::XLEN-1:0] instr [IssueWidth-1:0];
  logic [                4:0] reg_addr [IssueWidth-1:0];
  logic [riscv_pkg::XLEN-1:0] reg_data [IssueWidth-1:0];
  logic [riscv_pkg::XLEN-1:0] mem_addr [IssueWidth-1:0];
  logic [riscv_pkg::XLEN-1:0] mem_data [IssueWidth-1:0];
  logic                       mem_wrt [IssueWidth-1:0];
  logic                       update [IssueWidth-1:0];
  logic                       clk;
  logic                       rstn ;

  core_model  #(
    .DMemInitFile("./test/dmem.hex"),
    .IMemInitFile("./test/test.hex"),
    .TableFile   ("table.log"),
    .IssueWidth  (2)
  ) i_core_model (
      .clk_i(clk),
      .rstn_i(rstn),
      .addr_i(addr),
      .update_o(update),
      .data_o(data),
      .pc_o(pc),
      .instr_o(instr),
      .reg_addr_o(reg_addr),
      .reg_data_o(reg_data),
      .mem_addr_o(mem_addr),
      .mem_data_o(mem_data),
      .mem_wrt_o(mem_wrt)

  );
  integer file_pointer;
  integer stall_issue_mem = 0; // mem çıkışı write back de stall tespitinde model.log için kullan
  integer stall_issue_mem2 = 0; // mem çıkışı write back de stall tespitinde table.log kullan
  integer stall_issue_fe = 0;
  integer stall_issue_is = 0;
  integer stall_issue_de = 0;
  integer stall_issue_ex = 0;
  integer stall_issue_wb = 0;
  integer stall_en_mem = 0; //model.log için mem çıkışı
  integer stall_en_mem2 = 0; // table.log için mem çıkışı
  integer stall_en_fe = 0; 
  integer stall_en_de = 0; 
  integer stall_en_wb = 0; 
  integer stall_en_ex = 0; 
  integer stall_en_is = 0; 
  integer pipe_pc;
  initial begin
    file_pointer = $fopen("model.log", "w");
    if (file_pointer == 0) $display("File model.log was not opened");
    #2;
    wait(instr[0]!=32'h00000000);
    #2;    
    forever begin
      for (int i=0; i < IssueWidth; ++i) begin
        if (update[i]) begin
          //$fdisplay(file_pointer, "i=%0d", i);              
          if (reg_addr[i] == 5'b0 && instr[i][6:0] != 7'b0100011 && instr[i]!=32'h00000000 && stall_issue_mem == 0 && stall_en_mem == 0) begin // flush da yazmması için instr!=32'h00000000 ekledim. // instr[i][6:0] != 7'b0100011 stall da mem'e girsin diye yazdım
            //$fdisplay(file_pointer, "nerede1");
            //$fdisplay(file_pointer, "handle=%0d", i_core_model.stall_issue_handle_memory);
            //$fdisplay(file_pointer, "handle=%0d", i_core_model.stall_issue_handle_write_back);
            $fwrite(file_pointer, "0x%8h (0x%8h)", pc[i], instr[i]);
            $fwrite(file_pointer, "\n");
          end if (reg_addr[i] == 5'b0 && instr[i]!=32'h00000000 && (stall_issue_mem == 1 && instr[i][6:0] == 7'b1100011) && stall_en_mem == 0) begin // stall_issue 1 olup memory de nop,branch te breanch komutu olursa diye yazdım
            //$fdisplay(file_pointer, "nerede2");
            //$fdisplay(file_pointer, "handle=%0d", i_core_model.stall_issue_handle_memory);
            //$fdisplay(file_pointer, "handle=%0d", i_core_model.stall_issue_handle_write_back);
            $fwrite(file_pointer, "0x%8h (0x%8h)", pc[i], instr[i]);
            $fwrite(file_pointer, "\n");
          end else begin
            if (reg_addr[i] > 9) begin
             // $fdisplay(file_pointer, "nerede3");
              $fwrite(file_pointer, "0x%8h (0x%8h) x%0d 0x%8h", pc[i], instr[i], reg_addr[i], reg_data[i]);
              $fwrite(file_pointer, "\n");
            end else if(reg_addr[i] > 0) begin // nerede1 de stall ları koydugumuz için buraya giriyor >0 eklemezsek
              //$fdisplay(file_pointer, "nerede4");
              $fwrite(file_pointer, "0x%8h (0x%8h) x%0d  0x%8h", pc[i], instr[i], reg_addr[i], reg_data[i]);
              $fwrite(file_pointer, "\n");
            end
          end
          if (mem_wrt[i] == 1) begin
           // $fdisplay(file_pointer, "nerede_mem");
            $fwrite(file_pointer, "0x%8h (0x%8h) mem 0x%8h 0x%8h", pc[i], instr[i], mem_addr[i], mem_data[i]);
            $fwrite(file_pointer, "\n");
          end
          //if(instr[i]!=32'h00000000 || (instr[i]==32'h000000013 && stall_issue_mem == 1)) begin
          //  $fwrite(file_pointer, "\n");
          //end  
        end
      end
      @(negedge clk);
    end
  end
  initial
    forever begin
      clk = 0;
      #1;
      clk = 1;
      #1;
    end

  initial forever begin
    @(posedge i_core_model.stall_issue);
    #8;// model.log için bunu kullan, table.log için aşağıdaki 
    stall_issue_mem = 1;
    #4;
    stall_issue_mem = 0;
  end 

  initial forever begin
    @(posedge i_core_model.stall_issue);
    #8;
    #2;// table.log a yazdırırken 2 ns geçiyor ama tam clk gelmiyor inceki veriyi ya<dırıyor o yu<den böyle yaptım
    stall_issue_mem2 = 1;
    #4;
    stall_issue_mem2 = 0;
  end 

  initial forever begin
    @(posedge i_core_model.stall_issue);
    #4;// table.log a yazdırırken 2 ns geçiyor ama tam clk gelmiyor inceki veriyi ya<dırıyor o yu<den böyle yaptım
    stall_issue_fe = 1;
    stall_issue_is = 1;
    #2;
    stall_issue_fe = 0;
    stall_issue_de = 1;
    #2;
    stall_issue_is = 0;
    stall_issue_ex = 1;
    #2;
    stall_issue_de = 0; // mem yukarıda açtık
    #2;
    stall_issue_ex = 0;
    stall_issue_wb = 1;
    #4;
    stall_issue_wb = 0;
  end 

  //initial forever begin // arka arkaya sık stall_issue_handle yapacak waw raw gelince patlıyor delaler yüzünden core kısmına yaptım
  //  @(posedge i_core_model.stall_issue_handle);
  //  #4;// table.log a yazdırırken 2 ns geçiyor ama tam clk gelmiyor inceki veriyi ya<dırıyor o yu<den böyle yaptım
  //  stall_issue_handle_fe = 1;
  //  stall_issue_handle_is = 1;
  //  stall_issue_handle_de = 1;
  //  #2;
  //  stall_issue_handle_fe = 0;
  //  stall_issue_handle_is = 0;
  //  stall_issue_handle_ex = 1;
  //  #4;  // stall_issue_handle ve stall_en arka arkaya gelince sıkıntı oluyor o yüzden uzattım
  //  stall_issue_handle_de = 0;
  //  #2;
  //  stall_issue_handle_ex = 0; 
  //  #4; // stall_issue_handle ve stall_en arka arkaya gelince sıkıntı oluyor o yüzden uzattım
  //end 


  initial forever begin
    @(posedge i_core_model.stall_en);
    #6; // model.log için bunu kullan, table.log için aşağıdaki 
    stall_en_mem = 1;
    #2;
    stall_en_mem = 0;
  end 

  initial forever begin
    @(posedge i_core_model.stall_en);
    #6;
    #2;// table.log a yazdırırken 2 ns geçiyor ama tam clk gelmiyor inceki veriyi ya<dırıyor o yu<den böyle yaptım
    stall_en_mem2 = 1;
    #2;
    stall_en_mem2 = 0;
  end 

  initial forever begin
    @(posedge i_core_model.stall_en);
    #4; // table.log a yazdırırken 2 ns geçiyor ama tam clk gelmiyor inceki veriyi ya<dırıyor o yu<den böyle yaptım
    stall_en_fe = 1;
    stall_en_is = 1;
    stall_en_de = 1;
    #2;
    stall_en_fe = 0;
    stall_en_is = 0;
    stall_en_de = 0;
    stall_en_ex = 1;
    #2;
    stall_en_ex = 0;
    #2;
    stall_en_wb = 1;
    #2;
    stall_en_wb = 0;
  end 

  initial begin
    $display("starting\n");
    rstn = 0;
    #4;
    rstn = 1;
    #10000;
    for (logic [31:0] i = 32'h8000_0000; i < 32'h8000_0000 + 'h20; i = i + 4) begin
      addr = i;
      $display("data @ mem[0x%8h] = %8h", addr, data);
    end
    $finish;
  end

  initial begin
      pipe_pc = $fopen("table.log", "w");  
      $fdisplay(pipe_pc, "           Fetch          Issue          Decode         Execute        Space/Memory         Write Back\n");
      forever begin
          wait(rstn == 1);
          @(posedge clk);
          $fwrite(pipe_pc,"A       ");
          if(i_core_model.iss_inst.prio == 0) begin
            if(i_core_model.instr_fetch == 32'h00000000 && i_core_model.pc_fetch != 32'b0 && i_core_model.stall_issue_handle_fe == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
              $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
            end 
            else begin
              if(stall_en_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_en         ");
                  //$display("stalled x%0d",stall_f_d);
              end
              else if(stall_issue_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_issue      ");  
              end
              else if(i_core_model.stall_issue_handle_fe == 1) begin
                  $fwrite(pipe_pc,"stall_issue_handle  ");  
              end
              else begin
                  $fwrite(pipe_pc,"    0x%8h     ", i_core_model.pc_fetch); 
                  //$display("not stalled x%0d",stall_f_d);
              end
            end
          end
          else if(i_core_model.iss_inst.prio == 1) begin
            if(i_core_model.instr_fetch_2 == 32'h00000000 && i_core_model.pc_fetch_2 != 32'b0 && i_core_model.stall_issue_handle_fe == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
              $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
            end 
            else begin
              if(stall_en_fe == 1) begin
                  $fwrite(pipe_pc,"stall_en       ");
                  //$display("stalled x%0d",stall_f_d);
              end
              else if(stall_issue_fe == 1) begin
                  $fwrite(pipe_pc,"stall_issue    ");  
              end
              else if(i_core_model.stall_issue_handle_fe == 1) begin
                  $fwrite(pipe_pc,"stall_issue_handle  ");  
              end
              else begin
                  $fwrite(pipe_pc,"    0x%8h     ", i_core_model.pc_fetch_2); 
                  //$display("not stalled x%0d",stall_f_d);
              end
            end
          end

          if(i_core_model.instr_bra_int_iss == 32'h00000000 && i_core_model.pc_bra_int_iss != 32'b0 && i_core_model.stall_issue_handle_fe == 0 && stall_en_is == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_is == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_is == 1 && i_core_model.instr_bra_int_iss == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if(i_core_model.stall_issue_handle_fe == 1) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_bra_int_iss); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_decode_branch == 32'h00000000 && i_core_model.pc_decode_branch != 32'b0 && i_core_model.stall_issue_handle_de == 0 && i_core_model.stall_issue_handle_fe == 0 && stall_en_de == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_de == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_de == 1 && i_core_model.instr_decode_branch == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_de == 1 || i_core_model.stall_issue_handle_fe == 1) && i_core_model.instr_decode_branch == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_decode_branch); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_excte_branch == 32'h00000000 && i_core_model.pc_excte_branch != 32'b0 && i_core_model.stall_issue_handle_ex == 0 && i_core_model.stall_issue_handle_de == 0 && stall_en_ex == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_ex == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_ex == 1 && i_core_model.instr_excte_branch == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_ex == 1 || i_core_model.stall_issue_handle_de == 1)  && i_core_model.instr_excte_branch == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_excte_branch); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_space == 32'h00000000 && i_core_model.pc_space != 32'b0 && i_core_model.stall_issue_handle_mem == 0 && i_core_model.stall_issue_handle_ex == 0 && stall_en_mem == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_mem2 == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_mem2 == 1 && i_core_model.instr_space == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_mem == 1 || i_core_model.stall_issue_handle_ex == 1) && i_core_model.instr_space == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_space); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end        
          if(i_core_model.wrt_bck_inst.instr_o_space == 32'h00000000 && i_core_model.wrt_bck_inst.pc_o_space != 32'b0 && i_core_model.stall_issue_handle_wb == 0 && i_core_model.stall_issue_handle_mem == 0  && stall_en_wb == 0) begin
               $fwrite(pipe_pc,"FLUSHED        ");
          end 
          else begin
            if(stall_en_wb == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_wb == 1 && i_core_model.wrt_bck_inst.instr_o_space == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_wb == 1 || i_core_model.stall_issue_handle_mem == 1)  && i_core_model.wrt_bck_inst.instr_o_space == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.wrt_bck_inst.pc_o_space); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end                
          $fwrite(pipe_pc, "\n"); 

          $fwrite(pipe_pc,"B       ");
          if(i_core_model.iss_inst.prio == 1) begin
            if(i_core_model.instr_fetch == 32'h00000000 && i_core_model.pc_fetch != 32'b0 && i_core_model.stall_issue_handle_fe == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
              $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
            end 
            else begin
              if(stall_en_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_en        ");
                  //$display("stalled x%0d",stall_f_d);
              end
              else if(stall_issue_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_issue     ");  
              end
              else if(i_core_model.stall_issue_handle_fe == 1) begin
                  $fwrite(pipe_pc,"stall_issue_handle  ");  
              end
              else begin
                  $fwrite(pipe_pc,"    0x%8h     ", i_core_model.pc_fetch); 
                  //$display("not stalled x%0d",stall_f_d);
              end
            end
          end
          else if(i_core_model.iss_inst.prio == 0) begin
            if(i_core_model.instr_fetch_2 == 32'h00000000 && i_core_model.pc_fetch_2 != 32'b0 && i_core_model.stall_issue_handle_fe == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
              $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
            end 
            else begin
              if(stall_en_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_en         ");
                  //$display("stalled x%0d",stall_f_d);
              end
              else if(stall_issue_fe == 1) begin
                  $fwrite(pipe_pc,"  stall_issue      ");  
              end
              else if(i_core_model.stall_issue_handle_fe == 1) begin
                  $fwrite(pipe_pc,"stall_issue_handle  ");  
              end
              else begin
                  $fwrite(pipe_pc,"    0x%8h     ", i_core_model.pc_fetch_2); 
                  //$display("not stalled x%0d",stall_f_d);
              end
            end
          end

          if(i_core_model.instr_ls_int_iss == 32'h00000000 && i_core_model.pc_ls_int_iss != 32'b0 && i_core_model.stall_issue_handle_fe == 0 && stall_en_is == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_is == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_is == 1 && i_core_model.instr_ls_int_iss == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if(i_core_model.stall_issue_handle_fe == 1) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_ls_int_iss); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_decode_memory == 32'h00000000 && i_core_model.pc_decode_memory != 32'b0 && i_core_model.stall_issue_handle_de == 0 && i_core_model.stall_issue_handle_fe == 0 &&  stall_en_de == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_de == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_de == 1 && i_core_model.instr_decode_memory == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_de == 1 || i_core_model.stall_issue_handle_fe == 1) && i_core_model.instr_decode_memory == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_decode_memory); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_excte_memory == 32'h00000000 && i_core_model.pc_excte_memory != 32'b0 && i_core_model.stall_issue_handle_ex == 0 && i_core_model.stall_issue_handle_de == 0 && stall_en_ex == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_ex == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_ex == 1 && i_core_model.instr_excte_memory == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_ex == 1 || i_core_model.stall_issue_handle_de == 1) && i_core_model.instr_excte_memory == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_excte_memory); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          if(i_core_model.instr_memory == 32'h00000000 && i_core_model.pc_memory != 32'b0 && i_core_model.stall_issue_handle_mem == 0 && i_core_model.stall_issue_handle_ex == 0 && stall_en_mem == 0) begin // resette iken de instr = 0 oluyor. o yuzden pc ekledim.
            $fwrite(pipe_pc,"FLUSHED        "); // $fdisplay() her yazacağını bir alt satıra yazıyor 
          end
          else begin
            if(stall_en_mem2 == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_mem2 == 1 && i_core_model.instr_memory == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_mem == 1 || i_core_model.stall_issue_handle_ex == 1) && i_core_model.instr_memory == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.pc_memory); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end        
          if(i_core_model.wrt_bck_inst.instr_o_memory == 32'h00000000 && i_core_model.wrt_bck_inst.pc_o_memory != 32'b0 && i_core_model.stall_issue_handle_wb == 0 && i_core_model.stall_issue_handle_mem == 0 && stall_en_wb == 0) begin
               $fwrite(pipe_pc,"FLUSHED        ");
          end 
          else begin
            if(stall_en_wb == 1) begin
                $fwrite(pipe_pc,"stall_en       ");
                //$display("stalled x%0d",stall_f_d);
            end
            else if(stall_issue_wb == 1 && i_core_model.wrt_bck_inst.instr_o_memory == 32'h00000013) begin
                $fwrite(pipe_pc,"stall_issue    ");  
            end
            else if((i_core_model.stall_issue_handle_wb == 1 || i_core_model.stall_issue_handle_mem == 1) && i_core_model.wrt_bck_inst.instr_o_memory == 32'h00000000) begin
                $fwrite(pipe_pc,"stall_issue_handle  ");  
            end
            else begin
                $fwrite(pipe_pc,"0x%8h     ", i_core_model.wrt_bck_inst.pc_o_memory); 
                //$display("not stalled x%0d",stall_f_d);
            end
          end
          $fwrite(pipe_pc, "\n");  
      end
  end


  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

endmodule
