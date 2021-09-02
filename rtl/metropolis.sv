module metropolis
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic [base_log-1:0]     ex_base_id_r,
    input  logic [base_log-1:0]     ex_base_id_w,
    input  logic                    distance_shift,

    input  logic                    opt_run,
    input  opt_t                    in_opt,
    output opt_t                    opt_rep,
    output opt_t                    opt_ex,
    input  delata_data_t            delta_distance,
    
    input  logic                    exchange_mtr,
    input  total_data_t             prev_data,
    input  total_data_t             replica_data,
    output total_data_t             out_data,

    input  logic                    exp_init,
    input  logic                    exp_run,
    input  logic                    exp_fin,
    input  logic [16:0]             exp_recip
);

opt_t                    opt_metro;
delata_data_t            delta_distance_d;
always_ff @(posedge clk)begin
    if(reset)        opt_metro.com <= THR;
    else if(opt_run) opt_metro     <= in_opt;
    if(reset)        opt_rep.com   <= THR;
    else if(opt_run) opt_rep       <= opt_metro;
    if(opt_run) delta_distance_d <= delta_distance;
end

wire metropolis_run = exp_fin && (opt_metro.com != THR);

logic signed [26:0] n_metropolis;
exp #(
    .nbeta(dbeta * (id+1)),
    .step(dbeta * node_num)
) exp (
    .clk     ( clk             ),
    .base_id ( in_opt.base_id  ), // @ init
    .x       ( -delta_distance ), // @ init
    .y       ( n_metropolis    ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

wire test = (-delta_distance_d >= 0) || (n_metropolis > opt_metro.r_metropolis[22:0]);

wire signed [$bits(total_data_t):0] delta = $signed(delta_distance_d);

opt_command_t com1, com2;

total_data_t total_distance [0:base_num-1];
assign out_data = total_distance[ex_base_id_r];
always_ff @(posedge clk) begin
    if(metropolis_run && test) total_distance[opt_metro.base_id] <= total_distance[opt_metro.base_id] + delta;
    else if(exchange_mtr  )    total_distance[ex_base_id_w]      <= replica_data;
    else if(distance_shift)    total_distance[ex_base_id_w]      <= prev_data;
    
    if(reset)begin
        com1 <= THR;
    end else if(opt_metro.com == THR) begin
        com1 <= THR;
    end else if(metropolis_run) begin
        if(test) begin
            if(opt_metro.com == TWO) begin
                com1 <= TWO;
            end else begin
                if(opt_metro.K < opt_metro.L) com1 <= OR0;
                else                          com1 <= OR1;
            end
        end else begin
            com1 <= THR;
        end
    end
    if(reset)begin
        com2 <= THR;
        opt_ex.com <= THR;
    end else if(opt_run)begin
        com2 <= com1;
        opt_ex.com <= com2;

        opt_ex.base_id <= opt_rep.base_id;
        opt_ex.K <= opt_rep.K;
        opt_ex.L <= opt_rep.L;
        opt_ex.r_metropolis <= opt_rep.r_metropolis;
        opt_ex.r_exchange   <= opt_rep.r_exchange;
    end
end

endmodule