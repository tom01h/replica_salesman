module exp
#(
    parameter nbeta
)
(
    input  logic signed [20:0] x,  // .17
    output logic signed [26:0] y   // .23
);

logic signed [31:0] xx;     // .17
logic signed [17:0] z;      // .14
logic signed [16:0] recip;  // .15
logic               nega;

always_comb begin
    nega = 'b0;
    xx = $signed(x * nbeta);
    if(xx < -(8<<17)) nega = 'b1;

    recip = (1<<15) / 15;
    y = 1<<23;
    z = $signed(38'( $signed(xx[20:0]) * recip )) >>> 18;

    for(int i = 15; i > 0; i--)begin
        recip = (1<<15) / (i-1);

        y = $signed((43'b1<<(14+23)) + 43'(z * $signed(y[24:0]))) >>> 14;
        z = $signed(38'( $signed(xx[20:0]) * recip )) >>> 18;

        if(y < 0)  nega = 'b1;
    end

    if(nega) y = 0;
end

endmodule