module PE(
    input clk,kernel_rf_en,
    input signed[8:0]R0,R1,R2,R3,R4,R5,R6,R7,R8,
    input signed[15:0]kernel_data,
    output reg signed[24:0]conv0,conv1,conv2,conv3,conv4,conv5,conv6,conv7,conv8
);
    reg [3:0]counter;
    reg signed[15:0]kernel[8:0];

    always@(posedge clk)begin
        if(kernel_rf_en)begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    always @(*) begin
        kernel[counter-1] = (kernel_rf_en)? kernel[counter-1]:kernel_data;
    end

    always @(*) begin
        conv0 = R0 * kernel[0];
        conv1 = R1 * kernel[1];
        conv2 = R2 * kernel[2];
        conv3 = R3 * kernel[3];
        conv4 = R4 * kernel[4];
        conv5 = R5 * kernel[5];
        conv6 = R6 * kernel[6];
        conv7 = R7 * kernel[7];
        conv8 = R8 * kernel[8];
    end
endmodule