module partial_sum_dp_sram_control(
    input clk,ps_sram_en,ps_sram_rst_en,
    input [11:0]ps_sram_addr,
    input signed[35:0]ps_sram1_wr_data,ps_sram2_wr_data,ps_sram3_wr_data,ps_sram4_wr_data,
    output signed[35:0]ps_sram1_rd_data,ps_sram2_rd_data,ps_sram3_rd_data,ps_sram4_rd_data
);
    // A is read
    // B is write

    wire signed[35:0]data1,data2,data3,data4;

    assign data1 = (ps_sram_rst_en)? 0:ps_sram1_wr_data;
    assign data2 = (ps_sram_rst_en)? 0:ps_sram2_wr_data;
    assign data3 = (ps_sram_rst_en)? 0:ps_sram3_wr_data;
    assign data4 = (ps_sram_rst_en)? 0:ps_sram4_wr_data;

    partial_sum_sram PSSRAM1(.CENYA (),.WENYA(),.AYA(),.DYA(),.QA(ps_sram1_rd_data),
                             .CLKA(clk),.CENA(ps_sram_en),.WENA(1'b1),.AA(ps_sram_addr),.DA(36'd0),
                             .EMAA(3'b000),.EMAWA(2'b00),.EMASA(1'b0),.TENA(1'b1),.BENA(1'b1),.TCENA(1'b1),.TWENA(1'b1),
                             .TAA(12'd0),.TDA(36'd0),.RET1N(1'b1),.STOVA(1'b0),
                             
                             .CENYB(),.WENYB(),.AYB(),.DYB(),.QB(),
                             .CLKB(~clk),.CENB(ps_sram_en),.WENB(1'b0),.AB(ps_sram_addr),.DB(data1),
                             .EMAB(3'b000),.EMAWB(2'b00),.EMASB(1'b0),.TENB(1'b1),.BENB(1'b1),.TCENB(1'b1),.TWENB(1'b1),
                             .TAB(12'd0),.TDB(36'd0),.STOVB(1'b0),.COLLDISN(1'b1));
                             
    partial_sum_sram PSSRAM2(.CENYA (),.WENYA(),.AYA(),.DYA(),.QA(ps_sram2_rd_data),
                             .CLKA(clk),.CENA(ps_sram_en),.WENA(1'b1),.AA(ps_sram_addr),.DA(36'd0),
                             .EMAA(3'b000),.EMAWA(2'b00),.EMASA(1'b0),.TENA(1'b1),.BENA(1'b1),.TCENA(1'b1),.TWENA(1'b1),
                             .TAA(12'd0),.TDA(36'd0),.RET1N(1'b1),.STOVA(1'b0),
                             
                             .CENYB(),.WENYB(),.AYB(),.DYB(),.QB(),
                             .CLKB(~clk),.CENB(ps_sram_en),.WENB(1'b0),.AB(ps_sram_addr),.DB(data2),
                             .EMAB(3'b000),.EMAWB(2'b00),.EMASB(1'b0),.TENB(1'b1),.BENB(1'b1),.TCENB(1'b1),.TWENB(1'b1),
                             .TAB(12'd0),.TDB(36'd0),.STOVB(1'b0),.COLLDISN(1'b1));
                             
    partial_sum_sram PSSRAM3(.CENYA (),.WENYA(),.AYA(),.DYA(),.QA(ps_sram3_rd_data),
                             .CLKA(clk),.CENA(ps_sram_en),.WENA(1'b1),.AA(ps_sram_addr),.DA(36'd0),
                             .EMAA(3'b000),.EMAWA(2'b00),.EMASA(1'b0),.TENA(1'b1),.BENA(1'b1),.TCENA(1'b1),.TWENA(1'b1),
                             .TAA(12'd0),.TDA(36'd0),.RET1N(1'b1),.STOVA(1'b0),
                             
                             .CENYB(),.WENYB(),.AYB(),.DYB(),.QB(),
                             .CLKB(~clk),.CENB(ps_sram_en),.WENB(1'b0),.AB(ps_sram_addr),.DB(data3),
                             .EMAB(3'b000),.EMAWB(2'b00),.EMASB(1'b0),.TENB(1'b1),.BENB(1'b1),.TCENB(1'b1),.TWENB(1'b1),
                             .TAB(12'd0),.TDB(36'd0),.STOVB(1'b0),.COLLDISN(1'b1));
                             
    partial_sum_sram PSSRAM4(.CENYA (),.WENYA(),.AYA(),.DYA(),.QA(ps_sram4_rd_data),
                             .CLKA(clk),.CENA(ps_sram_en),.WENA(1'b1),.AA(ps_sram_addr),.DA(36'd0),
                             .EMAA(3'b000),.EMAWA(2'b00),.EMASA(1'b0),.TENA(1'b1),.BENA(1'b1),.TCENA(1'b1),.TWENA(1'b1),
                             .TAA(12'd0),.TDA(36'd0),.RET1N(1'b1),.STOVA(1'b0),
                             
                             .CENYB(),.WENYB(),.AYB(),.DYB(),.QB(),
                             .CLKB(~clk),.CENB(ps_sram_en),.WENB(1'b0),.AB(ps_sram_addr),.DB(data4),
                             .EMAB(3'b000),.EMAWB(2'b00),.EMASB(1'b0),.TENB(1'b1),.BENB(1'b1),.TCENB(1'b1),.TWENB(1'b1),
                             .TAB(12'd0),.TDB(36'd0),.STOVB(1'b0),.COLLDISN(1'b1));
endmodule