module exp
(
    input  logic signed [31:0] x,
    output logic signed [31:0] y
);

logic signed [31:0] z;
logic signed [31:0] recip;
logic               nega;

always_comb begin
    nega = 'b0;

    recip = (1<<15) / 15;
    y = 1<<23;
    z = (x * recip) >> 15;


    for(int i = 15; i > 0; i--)begin
        recip = (1<<15) / (i-1);

        y = (1<<(14+23) + z * y) >> 14;
        z = (x * recip) >> 15;

        if(y < 0)  nega = 'b1;
    end

    if(nega) y = 0;
end

endmodule