module random
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic [base_log-1:0]     or_base_id,
    input  logic [base_log-1:0]     tw_base_id,
    input  logic                    run,
    input  logic                    or_opt_en,
    input  logic                    tw_opt_en,
    input  logic                    init,
    input  logic                    read,
    input  logic [63:0]             w_seed,
    output logic [63:0]             r_seed,
    output opt_t                    or_opt,
    output opt_t                    tw_opt,
    output logic                    ready
);

logic [63:0]             seed [0:base_num-1];
logic [63:0]             or_seed_wd_w;
logic [63:0]             or_seed_wd;
logic [63:0]             tw_seed_wd;
logic [63:0]             or_seed_rd;
logic [63:0]             tw_seed_rd;
logic                    or_wen;
logic                    tw_wen;
logic                    or_run;
logic                    tw_run;

assign or_seed_wd_w = (init) ? w_seed : or_seed_wd;
assign or_wen = or_run | init;
assign tw_wen = tw_run;

always_ff @(posedge clk) begin
    if(or_wen) seed[or_base_id] <= or_seed_wd_w;
    or_seed_rd <= seed[or_base_id];
end

always_ff @(posedge clk) begin
    if(tw_wen) seed[tw_base_id] <= tw_seed_wd;
    tw_seed_rd <= seed[tw_base_id];
end

always_ff @(posedge clk)
    if(read) r_seed <= or_seed_rd;

logic or_ready, tw_ready;
assign ready = or_ready & tw_ready;

opt_t                    or_opt_w;

generate
if(id == node_num-1)
    always_ff @(posedge clk) begin if(run) or_opt <= or_opt_w; end
else
    always_comb              begin or_opt  = or_opt_w; end
endgenerate

or_rand or_rand (
    .clk      ( clk              ),
    .reset    ( reset            ),
    .base_id  ( or_base_id       ),
    .seed     ( or_seed_rd       ),
    .n_seed   ( or_seed_wd       ),
    .run_i    ( run              ),
    .run_o    ( or_run           ),
    .opt_en   ( or_opt_en        ),
    .opt      ( or_opt_w         ),
    .ready    ( or_ready         )
);

tw_rand tw_rand (
    .clk      ( clk              ),
    .reset    ( reset            ),
    .base_id  ( tw_base_id       ),
    .seed     ( tw_seed_rd       ),
    .n_seed   ( tw_seed_wd       ),
    .run_i    ( run              ),
    .run_o    ( tw_run           ),
    .opt_en   ( tw_opt_en        ),
    .opt      ( tw_opt           ),
    .ready    ( tw_ready         )
);

endmodule