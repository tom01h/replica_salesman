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
    input  opt_command_t            opt_com,
    output opt_t                    opt,
    output logic                    ready
);

logic [31:0]             val;

always_ff @(posedge clk)begin
    if(reset)               opt.com     <= THR;
    else if(run_i)
        if(opt_com == OR1)  opt.com     <= OR1;
        else                opt.com     <= THR;
    
    if(reset)               opt.base_id <= base_id;
    else if(run_i)
        if(opt_com == OR1)  opt.base_id <= base_id;
end

logic [63:0]             x0, x1, x2, x3;
logic [31:0]             msk;

always_comb begin
    x0 = seed;
    x1 = x0 ^ (x0 << 13);
    x2 = x1 ^ (x1 >> 7);
    x3 = x2 ^ (x2 << 17);
    n_seed = x3;
    val = x3 & msk;
end    

typedef enum logic [1:0] {
    s_K = 2'b00,
    s_L = 2'b01,
    s_metropolis = 2'b10,
    s_exchange = 2'b11
} state_t;

state_t state;

always_ff @(posedge clk) begin
    if(reset) begin
        run_o <= 'b0;
    end else if(run_i && (opt_com == OR1)) begin
        run_o <= 'b1;
        state <= s_K;
        ready <= 'b0;
        msk <= {($clog2(city_num-1)){1'b1}};
    end else if(run_o) begin
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
            s_metropolis : begin opt.r_metropolis <= val; state <= s_exchange; end
            s_exchange :   begin opt.r_exchange   <= val; run_o <= 'b0; ready <= 'b1; end
            default : ;
        endcase
    end    
end

endmodule