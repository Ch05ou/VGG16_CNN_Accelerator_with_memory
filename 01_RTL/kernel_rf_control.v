module kernel_rf_control(
    input clk,
    input kernel_rf_en,kernel_rf_wr_en,
    input [8:0]kernel_rf_wr_addr,
    input [8:0]kernel1_rf_rd_addr,
    input [8:0]kernel2_rf_rd_addr,
    input [8:0]kernel3_rf_rd_addr,
    input [8:0]kernel4_rf_rd_addr,
    input signed [15:0]kernel1_rf_wr_data,
    input signed [15:0]kernel2_rf_wr_data,
    input signed [15:0]kernel3_rf_wr_data,
    input signed [15:0]kernel4_rf_wr_data,
    output signed [15:0]kernel1_rf_rd_data,
    output signed [15:0]kernel2_rf_rd_data,
    output signed [15:0]kernel3_rf_rd_data,
    output signed [15:0]kernel4_rf_rd_data
);
    wire [8:0]kernel1_rf_addr = (kernel_rf_wr_en)? kernel1_rf_rd_addr:kernel_rf_wr_addr;
    wire [8:0]kernel2_rf_addr = (kernel_rf_wr_en)? kernel2_rf_rd_addr:kernel_rf_wr_addr;
    wire [8:0]kernel3_rf_addr = (kernel_rf_wr_en)? kernel3_rf_rd_addr:kernel_rf_wr_addr;
    wire [8:0]kernel4_rf_addr = (kernel_rf_wr_en)? kernel4_rf_rd_addr:kernel_rf_wr_addr;
    
    kernel_rf K1(.CENY(),.WENY(),.AY(),.DY(),.Q(kernel1_rf_rd_data),
                     .CLK(clk),.CEN(kernel_rf_en),.WEN(kernel_rf_wr_en),.A(kernel1_rf_addr),.D(kernel1_rf_wr_data),
                     .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                     .TA(9'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    kernel_rf K2(.CENY(),.WENY(),.AY(),.DY(),.Q(kernel2_rf_rd_data),
                     .CLK(clk),.CEN(kernel_rf_en),.WEN(kernel_rf_wr_en),.A(kernel2_rf_addr),.D(kernel2_rf_wr_data),
                     .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                     .TA(9'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    kernel_rf K3(.CENY(),.WENY(),.AY(),.DY(),.Q(kernel3_rf_rd_data),
                     .CLK(clk),.CEN(kernel_rf_en),.WEN(kernel_rf_wr_en),.A(kernel3_rf_addr),.D(kernel3_rf_wr_data),
                     .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                     .TA(9'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

    kernel_rf K4(.CENY(),.WENY(),.AY(),.DY(),.Q(kernel4_rf_rd_data),
                     .CLK(clk),.CEN(kernel_rf_en),.WEN(kernel_rf_wr_en),.A(kernel4_rf_addr),.D(kernel4_rf_wr_data),
                     .EMA(3'b000),.EMAW(2'b00),.EMAS(1'b0),.TEN(1'b1),.BEN(1'b1),.TCEN(1'b1),.TWEN(1'b1),
                     .TA(9'd0),.TD(16'd0),.RET1N(1'b1),.STOV(1'b0));

endmodule