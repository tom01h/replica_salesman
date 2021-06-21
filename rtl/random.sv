module random
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic [base_log-1:0]     base_id,
    input  logic                    run,
    input  opt_command_t            opt_com,
    input  logic                    init,
    input  logic [63:0]             i_seed,
    output opt_t                    or_opt,
    output opt_t                    tw_opt,
    output logic                    ready
);

logic [63:0]             seed [0:base_num-1];
logic [63:0]             or_seed;
logic [63:0]             tw_seed;
logic                    or_run;
logic                    tw_run;

always_ff @(posedge clk) begin
    if(init)        seed[base_id] <= i_seed;
    else if(or_run) seed[base_id] <= or_seed;
    else if(tw_run) seed[base_id] <= tw_seed;
end

logic or_ready, tw_ready;
assign ready = or_ready & tw_ready;

or_rand or_rand (
    .clk      ( clk           ),
    .reset    ( reset         ),
    .base_id  ( base_id       ),
    .seed     ( seed[base_id] ),
    .n_seed   ( or_seed       ),
    .run_i    ( run           ),
    .run_o    ( or_run        ),
    .opt_com  ( opt_com       ),
    .opt      ( or_opt        ),
    .ready    ( or_ready      )
);

tw_rand tw_rand (
    .clk      ( clk           ),
    .reset    ( reset         ),
    .base_id  ( base_id       ),
    .seed     ( seed[base_id] ),
    .n_seed   ( tw_seed       ),
    .run_i    ( run           ),
    .run_o    ( tw_run        ),
    .opt_com  ( opt_com       ),
    .opt      ( tw_opt        ),
    .ready    ( tw_ready      )
);

endmodule