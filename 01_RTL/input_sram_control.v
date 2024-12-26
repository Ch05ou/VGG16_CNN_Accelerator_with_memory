module input_sram_control(
    input clk,reset,input_sram_en,input_sram_wr_en,
    input [13:0]input_sram_wr_addr,input_sram_rd_addr,
    input [7:0]input_sram_data,
    output [7:0]input_sram_out_data
);
    wire [13:0]input_sram_addr = (input_sram_wr_en)? input_sram_rd_addr:input_sram_wr_addr;

    input_sram INPUT(.CENY(),.WENY(),.AY(),.DY(),.Q(input_sram_out_data),
                     .CLK(clk),.CEN(input_sram_en),.WEN(input_sram_wr_en),.A(input_sram_addr),.D(input_sram_data),
                     .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                     .TA(14'd0),.TD(8'd0),.RET1N(1'b1),.STOV(1'b0));

endmodule