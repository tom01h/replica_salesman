module random
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  opt_command_t            cmd,
    input  logic                    init,
    input  logic [63:0]             i_seed,
    input  logic                    run,
    output logic                    ready,
    output logic [6:0]              K,
    output logic [6:0]              L,
    output logic [31:0]             r_metropolis,
    output logic [31:0]             r_exchange
);

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
    if(reset) begin
        s_run <= 'b0;
    end else if(run) begin
        s_run <= 'b1;
        state <= s_K;
        ready <= 'b0;
        if(cmd == TWO) begin     // 2-opt
            msk <= {($clog2(city_num  )){1'b1}};
        end else begin           // or-opt
            msk <= {($clog2(city_num-1)){1'b1}};
        end
    end else if(s_run) begin
        case(state)
            s_K :
                if(cmd == TWO) begin
                    if(1 <= val && val <= city_num) begin
                        K <= val;
                        state <= s_L;
                    end
                end else begin
                    if(1 <= val && val <= city_num-1) begin
                        K <= val;
                        state <= s_L;
                    end
                end 
            s_L :
                if(cmd == TWO) begin
                    if(1 <= val && val <= city_num) begin
                        if(K>val) begin K <= val; L <= K;   end
                        else      begin           L <= val; end
                        if(K != val) begin state <= s_metropolis; msk <= '1; end
                        else         state <= s_K;
                    end
                end else begin
                    if(0 <= val && val <= city_num-1) begin
                        L <= val;
                        if(K != val && K != val+1) begin state <= s_metropolis; msk <= '1; end
                        else                       state <= s_K;
                    end
                end
            s_metropolis : begin r_metropolis <= val; state <= s_exchange; end
            s_exchange :   begin r_exchange   <= val; s_run <= 'b0; ready <= 'b1; end
            default : ;
        endcase
    end    
end

endmodule