module metropolis
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic [base_log-1:0]     base_id,
    input  logic                    distance_shift,

    input  logic                    opt_run,
    input  opt_t                    in_opt,
    output opt_t                    opt_rep,
    output opt_t                    opt_ex,
    input  delata_data_t            delta_distance,
    
    input  exchange_command_t       command,
    input  total_data_t             prev_data,
    input  total_data_t             self_data,
    input  total_data_t             folw_data,
    output total_data_t             out_data,

    input  logic                    exp_init,
    input  logic                    exp_run,
    input  logic                    exp_fin,
    input  logic [16:0]             exp_recip
);

opt_t                    opt_metro;
always_ff @(posedge clk)begin
    if(reset)        opt_metro.com <= THR;
    else if(opt_run) opt_metro     <= in_opt;
    if(reset)        opt_rep.com   <= THR;
    else if(opt_run) opt_rep       <= opt_metro;
end

logic                    metropolis_run;
assign metropolis_run = exp_fin && (opt_metro.com != THR);

logic               test;
logic signed [26:0] n_metropolis;
exp #(
    .nbeta(dbeta * (id+1)),
    .step(dbeta * node_num)
) exp (
    .clk     ( clk             ),
    .base_id ( base_id         ),
    .x       ( -delta_distance ),
    .y       ( n_metropolis    ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

assign test = (-delta_distance >= 0) || (n_metropolis > opt_metro.r_metropolis[22:0]);

total_data_t                        write_data;
logic signed [$bits(out_data):0]    delta;
assign delta = $signed(delta_distance);
assign write_data  = ( distance_shift) ?        prev_data :
                     (command == PREV) ?        prev_data :
                     (command == FOLW) ?        folw_data :
                     (command == SELF) ?        self_data :
                     (metropolis_run && test) ? out_data + delta :
                                                out_data;

opt_command_t com1, com2;

total_data_t total_distance [0:base_num-1];
assign out_data = total_distance[base_id];
always_ff @(posedge clk) begin
    total_distance[base_id] <= write_data;
    opt_ex.K <= opt_rep.K;
    opt_ex.L <= opt_rep.L;
    opt_ex.r_metropolis <= opt_rep.r_metropolis;
    opt_ex.r_exchange   <= opt_rep.r_exchange;

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
    end
end

endmodule