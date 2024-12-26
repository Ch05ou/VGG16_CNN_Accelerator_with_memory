module ReLU(
    input signed[15:0]bias,
    input signed[35:0]partial_sum,
    output reg signed[35:0]result
);
    
    always@(*)begin
        result = (partial_sum+bias > 0)? partial_sum+bias:0;
    end

endmodule