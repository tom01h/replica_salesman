module exp
#(
    parameter nbeta
)
(
    input  logic               clk,
    input  logic signed [20:0] x,  // .17
    output logic signed [26:0] y,   // .23
    input  logic               init,
    input  logic               run,
    input  logic [16:0]        recip
);

logic               init_l;
logic               run_l;
logic signed [31:0] xx;      // .17
logic signed [26:0] yy;      // .23
logic signed [17:0] zz;      // .14

logic signed [24:0] a0, a1;
logic signed [17:0] b0, b1;
logic               nega;

always_ff @(posedge clk) begin
    init_l <= init;
    run_l  <= run;
    
    if(init) begin
        a0 <= $signed(x);
        b0 <= $signed(nbeta);
        nega <= 'b0;
    end else if (run || run_l) begin
        a1 <= $signed(yy[24:0]);
        b1 <= zz;
        if(~run_l) begin
            a0 <= $signed(xx[20:0]);        // hold xx
            if(xx < -(8<<17)) nega <= 'b1;  // xx range over
        end
        b0 <= recip;
        if(yy < 0) nega <= 'b1;
    end

    if(nega || yy < 0) y <= 'b0;
    else               y <= yy;
end

always_comb begin
    xx = a0 * b0;                                                     // (x * nbeta)
    if(init_l) yy = 0;
    else       yy = $signed((43'b1<<(14+23)) + 43'(a1 * b1)) >>> 14;  // ($signed(yy[24:0] * zz))
    zz = $signed(38'(a0 * b0)) >>> 18;                                // ($signed(xx[20:0]) * recip )
end

/*
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
end*/
endmodule