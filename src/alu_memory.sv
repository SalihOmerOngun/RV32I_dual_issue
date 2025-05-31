`timescale 1 ns / 1 ps

module alu_memory  // alu
(
    input logic [31:0] number1,      // Kaynak register 1 (rs1)
    input logic [31:0] number2,      // Kaynak register 2 (rs2)
    input logic [4:0] shamt_data,    // Immediate shift miktarı
    input logic [4:0] sel,           // ALU MUX seçim sinyali 
    output logic [31:0] alu_out      // ALU sonucu // execute ver
);

    logic [4:0] result;
    integer i;
    logic [15:0] val16;
    logic [7:0]  val8;
    logic [3:0]  val4;
    logic [1:0]  val2;

    always_comb begin
        alu_out = 32'b0;
        result = 5'b0;
        val16 = 16'b0;
        val8 = 8'b0;
        val4 = 4'b0;
        val2 = 2'b0;
        case (sel)
            5'b00000: alu_out = number1 + number2;  // ADD  
            5'b00001: alu_out = number1 - number2;  // SUB
            5'b00010: alu_out = number1 | number2;  // OR
            5'b00011: alu_out = number1 ^ number2;  // XOR
            5'b00100: alu_out = number1 & number2;  // AND
            5'b00101: alu_out = number1 << number2;  // **SLL (rs1 << rs2)**
            5'b00110: alu_out = number1 >> number2;  // **SRL (rs1 >> rs2)**
            5'b00111: alu_out =  $signed(number1) >>> number2; // **SRA (rs1 >>> rs2)**
            5'b01000: alu_out = number1 << shamt_data;  // **SLLI (rs1 << imm)**
            5'b01001: alu_out = number1 >> shamt_data;  // **SRLI (rs1 >> imm)**
            5'b01010: alu_out = number1 >>> shamt_data; // **SRAI (rs1 >>> imm)**
            5'b01011: alu_out = 32'd0;  // **Sabit 0 döndür**  // 11
            5'b01100: alu_out = 32'd1;  // **Sabit 1 döndür**  // 12
            5'b01101: alu_out = number1;  // **RS1'i direkt çıkışa ver** // 13
            5'b01110: begin  // CLZ // 14
                if(number1 == 32'b0) begin
                    alu_out = 32'd32; // asagidaki hesapla yaparsak 31 geliyor 
                end 
                else begin    
                    result[4] = (number1[31:16] == 16'b0);
                    val16 = result[4] ? number1[15:0] : number1[31:16]; 
                    result[3] = (val16[15:8] == 8'b0);
                    val8 = result[3] ? val16[7:0] : val16[15:8];
                    result[2] = (val8[7:4] == 4'b0);
                    val4 = result[2] ? val8[3:0] : val8[7:4];
                    result[1] = (val4[3:2] == 2'b0);
                    val2 = result[1] ? val4[1:0] : val4[3:2];
                    result[0] = (val2[1] == 1'b0);                
                    alu_out = {27'b0,result};
                end
            end     
            5'b01111: begin  // CTZ // 15
                if(number1 == 32'b0) begin
                    alu_out = 32'd32; // asagidaki hesapla yaparsak 31 geliyor 
                end 
                else begin    
                    result[4] = (number1[15:0] == 16'b0);
                    val16 = result[4] ? number1[31:16] : number1[15:0];
                    result[3] = (val16[7:0] == 8'b0);
                    val8 = result[3] ? val16[15:8] : val16[7:0];
                    result[2] = (val8[3:0] == 4'b0);
                    val4 = result[2] ? val8[7:4] : val8[3:0];
                    result[1] = (val4[1:0] == 2'b0);
                    val2 = result[1] ? val4[3:2] : val4[1:0];
                    result[0] = (val2[0] == 1'b0);
                    alu_out = {27'b0,result};
                end                
            end    
            5'b10000: begin // CPOP // 16
                for (i = 0 ; i < 32; i = i+1) begin
                    alu_out = alu_out + {31'b0, number1[i]};
                end
            end
            default: begin
                alu_out = 32'b0;
                result = 5'b0;
                val16 = 16'b0;
                val8 = 8'b0;
                val4 = 4'b0;
                val2 = 2'b0;
            end    
        endcase
    end
endmodule
