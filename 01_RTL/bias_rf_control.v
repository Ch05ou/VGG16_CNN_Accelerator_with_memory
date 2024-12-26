module bias_rf_control(
    input clk,
    input bias_rf_en,bias_rf_wr_en,
    input [3:0]bias_rf_wr_addr,bias_rf_rd_addr,
    input signed[15:0]bias_rf1_wr_data,bias_rf2_wr_data,bias_rf3_wr_data,bias_rf4_wr_data,
    output signed[15:0]bias_rf1_rd_data,bias_rf2_rd_data,bias_rf3_rd_data,bias_rf4_rd_data
);
    wire [3:0]bias_rf_addr = (bias_rf_wr_en)? bias_rf_rd_addr:bias_rf_wr_addr;

    bias_rf BIAS1(.CENY(),.WENY(),.AY(),.DY(),.Q(bias_rf1_rd_data),
                 .CLK(clk),.CEN(bias_rf_en),.WEN(bias_rf_wr_en),.A(bias_rf_addr),.D(bias_rf1_wr_data),
                 .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                 .TA(4'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    bias_rf BIAS2(.CENY(),.WENY(),.AY(),.DY(),.Q(bias_rf2_rd_data),
                 .CLK(clk),.CEN(bias_rf_en),.WEN(bias_rf_wr_en),.A(bias_rf_addr),.D(bias_rf2_wr_data),
                 .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                 .TA(4'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    bias_rf BIAS3(.CENY(),.WENY(),.AY(),.DY(),.Q(bias_rf3_rd_data),
                 .CLK(clk),.CEN(bias_rf_en),.WEN(bias_rf_wr_en),.A(bias_rf_addr),.D(bias_rf3_wr_data),
                 .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                 .TA(4'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    bias_rf BIAS4(.CENY(),.WENY(),.AY(),.DY(),.Q(bias_rf4_rd_data),
                 .CLK(clk),.CEN(bias_rf_en),.WEN(bias_rf_wr_en),.A(bias_rf_addr),.D(bias_rf4_wr_data),
                 .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                 .TA(4'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));
endmodule