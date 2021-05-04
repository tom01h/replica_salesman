module exp
#(
    parameter nbeta
)
(
    input  logic               clk,
    input  logic signed [20:0] x,   // .17
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
int m_y;      // .23
int m_xx;     // .17
int m_z;      // .14
int m_recip;  // .15
logic m_nega;
int cnt = 20;
logic fin;

always_ff @(posedge clk) begin
    if(init) begin
        m_nega = 'b0;
        m_xx = $signed(x * nbeta);
        if(m_xx < -(8<<17)) m_nega = 'b1;

        m_recip = (1<<15) / 15;
        m_y = 1<<23;
        m_z = $signed(64'( $signed(m_xx[20:0]) * m_recip )) >>> 18;

        for(int i = 15; i > 0; i--)begin
            m_recip = (1<<15) / (i-1);

            m_y = $signed((43'b1<<(14+23)) + 64'(m_z * $signed(m_y[24:0]))) >>> 14;
            m_z = $signed(64'( $signed(m_xx[20:0]) * m_recip )) >>> 18;

            if(m_y < 0)  m_nega = 'b1;
        end

        if(m_nega) m_y = 0;
        cnt = 0;
    end
    if(cnt<=20)
        cnt = cnt + 1;
    fin = (cnt==19);
    if(fin && m_y != y) $display("error %m",x,y,m_y);

end/**/
endmodule