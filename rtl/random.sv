module random
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    run,
    input  opt_command_t            opt_com,
    input  logic                    init,
    input  logic [63:0]             i_seed,
    output opt_t                    or_opt,
    output opt_t                    tw_opt,
    output logic                    ready
);

opt_command_t or_com, tw_com;

always_ff @(posedge clk)begin
    if(reset)               or_com      <= THR;
    else if(run)
        if(opt_com == OR1)  or_com      <= OR1;
        else                or_com      <= THR;
    if(reset)               tw_com      <= THR;
    else if(run)
        if(opt_com == TWO)  tw_com      <= TWO;
        else                tw_com      <= THR;
end

opt_t                    opt;

assign or_opt.com = or_com;
assign tw_opt.com = tw_com;
assign or_opt.K = opt.K;
assign tw_opt.K = opt.K;
assign or_opt.L = opt.L;
assign tw_opt.L = opt.L;
assign or_opt.r_metropolis = opt.r_metropolis;
assign tw_opt.r_metropolis = opt.r_metropolis;
assign or_opt.r_exchange = opt.r_exchange;
assign tw_opt.r_exchange = opt.r_exchange;



logic [63:0]             seed, n_seed;
logic [63:0]             x0, x1, x2, x3;
logic [31:0]             val;
logic [31:0]             msk;
logic                    s_run;

always_comb begin
    x0 = seed;
    x1 = x0 ^ (x0 << 13);
    x2 = x1 ^ (x1 >> 7);
    x3 = x2 ^ (x2 << 17);
    n_seed = x3;
    val = x3 & msk;
end    

always_ff @(posedge clk) begin
    if(reset)        seed <= 'b0;
    else if(init)    seed <= i_seed;
    else if(s_run)   seed <= n_seed;
end

typedef enum logic [1:0] {
    s_K = 2'b00,
    s_L = 2'b01,
    s_metropolis = 2'b10,
    s_exchange = 2'b11
} state_t;

state_t state;

always_ff @(posedge clk) begin
    opt.com      <= opt_com;
    if(reset) begin
        s_run <= 'b0;
    end else if(run && (opt_com != THR)) begin
        s_run <= 'b1;
        state <= s_K;
        ready <= 'b0;
        if(opt_com == TWO) begin     // 2-opt
            msk <= {($clog2(city_num  )){1'b1}};
        end else begin           // or-opt
            msk <= {($clog2(city_num-1)){1'b1}};
        end
    end else if(s_run) begin
        case(state)
            s_K :
                if(opt.com == TWO) begin
                    if(1 <= val && val <= city_num) begin
                        opt.K <= val;
                        state <= s_L;
                    end
                end else begin
                    if(1 <= val && val <= city_num-1) begin
                        opt.K <= val;
                        state <= s_L;
                    end
                end 
            s_L :
                if(opt.com == TWO) begin
                    if(1 <= val && val <= city_num) begin
                        if(opt.K>val) begin  opt.K <= val; opt.L <= opt.K;   end
                        else          begin                opt.L <= val; end
                        if(opt.K != val) begin state <= s_metropolis; msk <= '1; end
                        else                   state <= s_K;
                    end
                end else begin
                    if(0 <= val && val <= city_num-1) begin
                        opt.L <= val;
                        if(opt.K != val && opt.K != val+1) begin state <= s_metropolis; msk <= '1; end
                        else                                     state <= s_K;
                    end
                end
            s_metropolis : begin opt.r_metropolis <= val; state <= s_exchange; end
            s_exchange :   begin opt.r_exchange   <= val; s_run <= 'b0; ready <= 'b1; end
            default : ;
        endcase
    end    
end

endmodule