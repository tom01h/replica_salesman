module or_rand
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic [base_log-1:0]     base_id,
    input  logic [63:0]             seed,
    output logic [63:0]             n_seed,

    input  logic                    run_i,
    output logic                    run_o,
    input  logic                    opt_en,
    output opt_t                    opt,
    output logic                    ready
);

always_ff @(posedge clk)begin
    if(reset)       opt.com     <= THR;
    else if(run_i)
        if(opt_en)  opt.com     <= OR1;
        else        opt.com     <= THR;
    
    if(reset)       opt.base_id <= base_id;
    else if(run_i)
        if(opt_en)  opt.base_id <= base_id;
end

typedef enum logic [2:0] {
    s_NOP        = 3'b111,
    s_start      = 3'b100,
    s_K          = 3'b000,
    s_L          = 3'b001,
    s_metropolis = 3'b010,
    s_exchange   = 3'b011
} state_t;

state_t state;

logic [63:0]             seed_l;
logic                    run_l;

always_ff @(posedge clk) begin
    if(state==s_start) seed_l <= seed;
    else if(run_l)     seed_l <= n_seed;
end

logic [63:0]             x0, x1, x2, x3;
logic [31:0]             msk;
logic [31:0]             val;

always_comb begin
    x0 = seed_l;
    x1 = x0 ^ (x0 << 13);
    x2 = x1 ^ (x1 >> 7);
    x3 = x2 ^ (x2 << 17);
    n_seed = x3;
    val = x3 & msk;
end    

always_ff @(posedge clk) begin
    if(reset) begin
        run_o <= 'b0;
        run_l <= 'b0;
        ready <= 'b1;
        state <= s_NOP;
    end else if(run_i && opt_en) begin
        state <= s_start;
        msk <= {($clog2(city_num-1)){1'b1}};
    end else if(state == s_start) begin
        run_l <= 'b1;
        state <= s_K;
        ready <= 'b0;
    end else if(run_l) begin
        case(state)
            s_K :
                if(1 <= val && val <= city_num-1) begin
                    opt.K <= val;
                    state <= s_L;
                end
            s_L :
                if(0 <= val && val <= city_num-1) begin
                    opt.L <= val;
                    if(opt.K != val && opt.K != val+1) begin state <= s_metropolis; msk <= '1; end
                    else                                     state <= s_K;
                end
            s_metropolis : begin opt.r_metropolis <= val; run_o <= 'b1; state <= s_exchange; end
            s_exchange :   begin opt.r_exchange   <= val; run_o <= 'b0; state <= s_NOP; run_l <= 'b0; ready <= 'b1; end
            default : ;
        endcase
    end    
end

endmodule