module LineBuffer(
    input clk,rst,
    input [8:0]Y,
    input [13:0]input_sram_rd_addr,
    output [8:0]R0,R1,R2,R3,R4,R5,R6,R7,R8
);
    parameter img_h = 58;
    parameter img_w = 58;

    reg [8:0]LB1[0:img_w-1];
    reg [8:0]LB2[0:img_w-1];
    reg [8:0]LB3[0:2];
    integer i;

    assign R0 = LB1[0];
    assign R1 = LB1[1];
    assign R2 = LB1[2];
    assign R3 = LB2[0];
    assign R4 = LB2[1];
    assign R5 = LB2[2];
    assign R6 = LB3[0];
    assign R7 = LB3[1];
    assign R8 = LB3[2];

    always @(posedge clk , posedge rst) begin
        if(rst)begin
            //counter <= 0;
            for(i=0;i<img_w;i=i+1)begin
                LB1[i] <= 20'd0;
                LB2[i] <= 20'd0;
            end
            LB3[0] <= 20'd0;
            LB3[1] <= 20'd0;
            LB3[2] <= 20'd0;
        end
        else begin
            LB3[2] <= Y;
            LB3[1] <= LB3[2];
            LB3[0] <= LB3[1];
            
            LB2[img_w-1] <= LB3[0];
            LB1[img_w-1] <= LB2[0];
            for(i=img_w-2;i>=0;i=i-1)begin
                LB1[i] <= LB1[i+1];
                LB2[i] <= LB2[i+1];
            end
        end
    end

endmodule