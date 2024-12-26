// AT as Adder Tree
module AT(
    input clk,
    input signed[24:0]conv0,conv1,conv2,conv3,conv4,conv5,conv6,conv7,conv8,
    input signed[35:0]partial_sum,
    output reg signed[35:0]sum
);
    reg signed[25:0]tmp01,tmp23,tmp45,tmp67,tmp8;
    reg signed[26:0]tmp0123,tmp4567,tmp8_2;
    reg signed[27:0]tmp027,tmp8_3;

    always @(*) begin
        tmp01 = conv0 + conv1;
        tmp23 = conv2 + conv3;
        tmp45 = conv4 + conv5;
        tmp67 = conv6 + conv7;
        tmp8 = conv8;
    end

    always @(*)begin
        tmp0123 = tmp01 + tmp23;
        tmp4567 = tmp45 + tmp67;
        tmp8_2 = tmp8;
    end

    always @(*) begin
        tmp027 = tmp0123 + tmp4567;
        tmp8_3 = tmp8_2;
    end
    
    always @(*) begin
        sum = tmp027 + tmp8_3 + partial_sum;
    end

    /*always @(posedge clk) begin
        sum = conv0+conv1+conv2+conv3+conv4+conv5+conv6+conv7+conv8 + partial_sum;
    end*/

    /*always @(*) begin
        sum = conv0+conv1+conv2+conv3+conv4+conv5+conv6+conv7+conv8 + partial_sum;
    end*/
endmodule