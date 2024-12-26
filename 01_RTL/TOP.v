module TOP(
    input clk,reset,
    input input_sram_en,input_sram_wr_en,
    input [13:0]input_sram_wr_addr,input_sram_rd_addr,
    input [7:0]input_sram_data,

    input bias_rf_en,bias_rf_wr_en,
    input [3:0]bias_rf_wr_addr,
    input [3:0]bias_rf_rd_addr,
    input signed[15:0]bias_rf1_wr_data,bias_rf2_wr_data,bias_rf3_wr_data,bias_rf4_wr_data,

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

    input ps_sram_en,ps_sram_rst_en,
    input [11:0]ps_sram_addr,
    output signed[35:0]result1,result2,result3,result4
);
    parameter img_h = 58;
    parameter img_w = 58;

    wire signed [15:0]kernel1_rf_rd_data;
    wire signed [15:0]kernel2_rf_rd_data;
    wire signed [15:0]kernel3_rf_rd_data;
    wire signed [15:0]kernel4_rf_rd_data;

    
    wire signed[15:0]bias_rf1_rd_data,bias_rf2_rd_data,bias_rf3_rd_data,bias_rf4_rd_data;

    wire [7:0]input_sram_out_data;
    wire [8:0]R[8:0];

    wire signed[24:0]conv[8:0][3:0];
    wire signed[35:0]AT_sum[3:0];

    wire signed[35:0]ps_sram1_wr_data,ps_sram2_wr_data,ps_sram3_wr_data,ps_sram4_wr_data;

    wire [8:0]input_data = (input_sram_wr_en)? {1'b0,input_sram_out_data}:0;

    wire signed[35:0]ps_sram1_rd_data,ps_sram2_rd_data,ps_sram3_rd_data,ps_sram4_rd_data;

    input_sram_control ISC(.clk(clk),.reset(reset),
                           .input_sram_en(input_sram_en),.input_sram_wr_en(input_sram_wr_en),
                           .input_sram_wr_addr(input_sram_wr_addr),.input_sram_rd_addr(input_sram_rd_addr),
                           .input_sram_data(input_sram_data),.input_sram_out_data(input_sram_out_data));

    bias_rf_control BRFC(.clk(clk),
                         .bias_rf_en(bias_rf_en),.bias_rf_wr_en(bias_rf_wr_en),
                         .bias_rf_wr_addr(bias_rf_wr_addr),
                         .bias_rf_rd_addr(bias_rf_rd_addr),
                         .bias_rf1_wr_data(bias_rf1_wr_data),.bias_rf2_wr_data(bias_rf2_wr_data),
                         .bias_rf3_wr_data(bias_rf3_wr_data),.bias_rf4_wr_data(bias_rf4_wr_data),
                         
                         .bias_rf1_rd_data(bias_rf1_rd_data),.bias_rf2_rd_data(bias_rf2_rd_data),
                         .bias_rf3_rd_data(bias_rf3_rd_data),.bias_rf4_rd_data(bias_rf4_rd_data));

    kernel_rf_control KRFC(.clk(clk),
                           .kernel_rf_en(kernel_rf_en),.kernel_rf_wr_en(kernel_rf_wr_en),
                           .kernel_rf_wr_addr(kernel_rf_wr_addr),

                           .kernel1_rf_rd_addr(kernel1_rf_rd_addr),
                           .kernel2_rf_rd_addr(kernel2_rf_rd_addr),
                           .kernel3_rf_rd_addr(kernel3_rf_rd_addr),
                           .kernel4_rf_rd_addr(kernel4_rf_rd_addr),

                           .kernel1_rf_wr_data(kernel1_rf_wr_data),.kernel2_rf_wr_data(kernel2_rf_wr_data),
                           .kernel3_rf_wr_data(kernel3_rf_wr_data),.kernel4_rf_wr_data(kernel4_rf_wr_data),

                           .kernel1_rf_rd_data(kernel1_rf_rd_data),.kernel2_rf_rd_data(kernel2_rf_rd_data),
                           .kernel3_rf_rd_data(kernel3_rf_rd_data),.kernel4_rf_rd_data(kernel4_rf_rd_data));
       
    partial_sum_dp_sram_control PSSC(.clk(clk),.ps_sram_en(ps_sram_en),.ps_sram_rst_en(ps_sram_rst_en),
                                     .ps_sram_addr(ps_sram_addr),
                                     .ps_sram1_wr_data(ps_sram1_wr_data),.ps_sram2_wr_data(ps_sram2_wr_data),
                                     .ps_sram3_wr_data(ps_sram3_wr_data),.ps_sram4_wr_data(ps_sram4_wr_data),
                                     .ps_sram1_rd_data(ps_sram1_rd_data),.ps_sram2_rd_data(ps_sram2_rd_data),
                                     .ps_sram3_rd_data(ps_sram3_rd_data),.ps_sram4_rd_data(ps_sram4_rd_data));

    LineBuffer  LB(.clk(clk),.rst(reset),
                   .Y(input_data),.input_sram_rd_addr(input_sram_rd_addr),
                   .R0(R[0]),.R1(R[1]),.R2(R[2]),
                   .R3(R[3]),.R4(R[4]),.R5(R[5]),
                   .R6(R[6]),.R7(R[7]),.R8(R[8]));
    
    PE PE1(.clk(clk),.kernel_rf_en(kernel_rf_en),
           .R0(R[0]),.R1(R[1]),.R2(R[2]),.R3(R[3]),.R4(R[4]),.R5(R[5]),.R6(R[6]),.R7(R[7]),.R8(R[8]),
           .kernel_data(kernel1_rf_rd_data),
           .conv0(conv[0][0]),.conv1(conv[1][0]),.conv2(conv[2][0]),
           .conv3(conv[3][0]),.conv4(conv[4][0]),.conv5(conv[5][0]),
           .conv6(conv[6][0]),.conv7(conv[7][0]),.conv8(conv[8][0]));

    PE PE2(.clk(clk),.kernel_rf_en(kernel_rf_en),
           .R0(R[0]),.R1(R[1]),.R2(R[2]),.R3(R[3]),.R4(R[4]),.R5(R[5]),.R6(R[6]),.R7(R[7]),.R8(R[8]),
           .kernel_data(kernel2_rf_rd_data),
           .conv0(conv[0][1]),.conv1(conv[1][1]),.conv2(conv[2][1]),
           .conv3(conv[3][1]),.conv4(conv[4][1]),.conv5(conv[5][1]),
           .conv6(conv[6][1]),.conv7(conv[7][1]),.conv8(conv[8][1]));
           
    PE PE3(.clk(clk),.kernel_rf_en(kernel_rf_en),
           .R0(R[0]),.R1(R[1]),.R2(R[2]),.R3(R[3]),.R4(R[4]),.R5(R[5]),.R6(R[6]),.R7(R[7]),.R8(R[8]),
           .kernel_data(kernel3_rf_rd_data),
           .conv0(conv[0][2]),.conv1(conv[1][2]),.conv2(conv[2][2]),
           .conv3(conv[3][2]),.conv4(conv[4][2]),.conv5(conv[5][2]),
           .conv6(conv[6][2]),.conv7(conv[7][2]),.conv8(conv[8][2]));
           
    PE PE4(.clk(clk),.kernel_rf_en(kernel_rf_en),
           .R0(R[0]),.R1(R[1]),.R2(R[2]),.R3(R[3]),.R4(R[4]),.R5(R[5]),.R6(R[6]),.R7(R[7]),.R8(R[8]),
           .kernel_data(kernel4_rf_rd_data),
           .conv0(conv[0][3]),.conv1(conv[1][3]),.conv2(conv[2][3]),
           .conv3(conv[3][3]),.conv4(conv[4][3]),.conv5(conv[5][3]),
           .conv6(conv[6][3]),.conv7(conv[7][3]),.conv8(conv[8][3]));

    AT PE1AT(.clk(clk),
             .conv0(conv[0][0]),.conv1(conv[1][0]),.conv2(conv[2][0]),
             .conv3(conv[3][0]),.conv4(conv[4][0]),.conv5(conv[5][0]),
             .conv6(conv[6][0]),.conv7(conv[7][0]),.conv8(conv[8][0]),
             .partial_sum(ps_sram1_rd_data),
             .sum(ps_sram1_wr_data));

    AT PE2AT(.clk(clk),
             .conv0(conv[0][1]),.conv1(conv[1][1]),.conv2(conv[2][1]),
             .conv3(conv[3][1]),.conv4(conv[4][1]),.conv5(conv[5][1]),
             .conv6(conv[6][1]),.conv7(conv[7][1]),.conv8(conv[8][1]),
             .partial_sum(ps_sram2_rd_data),
             .sum(ps_sram2_wr_data));

    AT PE3AT(.clk(clk),
             .conv0(conv[0][2]),.conv1(conv[1][2]),.conv2(conv[2][2]),
             .conv3(conv[3][2]),.conv4(conv[4][2]),.conv5(conv[5][2]),
             .conv6(conv[6][2]),.conv7(conv[7][2]),.conv8(conv[8][2]),
             .partial_sum(ps_sram3_rd_data),
             .sum(ps_sram3_wr_data));

    AT PE4AT(.clk(clk),
             .conv0(conv[0][3]),.conv1(conv[1][3]),.conv2(conv[2][3]),
             .conv3(conv[3][3]),.conv4(conv[4][3]),.conv5(conv[5][3]),
             .conv6(conv[6][3]),.conv7(conv[7][3]),.conv8(conv[8][3]),
             .partial_sum(ps_sram4_rd_data),
             .sum(ps_sram4_wr_data));

    ReLU ReLU1(.bias(bias_rf1_rd_data),.partial_sum(ps_sram1_rd_data),.result(result1));
    ReLU ReLU2(.bias(bias_rf2_rd_data),.partial_sum(ps_sram2_rd_data),.result(result2));
    ReLU ReLU3(.bias(bias_rf3_rd_data),.partial_sum(ps_sram3_rd_data),.result(result3));
    ReLU ReLU4(.bias(bias_rf4_rd_data),.partial_sum(ps_sram4_rd_data),.result(result4));

endmodule