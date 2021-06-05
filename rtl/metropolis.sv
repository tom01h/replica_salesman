module metropolis
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic                    distance_shift,

    input  logic                    metropolis_run,
    input  opt_t                    in_opt,
    output opt_t                    out_opt,
    input  delata_data_t            delta_distance,
    
    input  exchange_command_t       command,
    input  total_data_t             prev_data,
    input  total_data_t             self_data,
    input  total_data_t             folw_data,
    output total_data_t             out_data,

    input  logic                    exp_init,
    input  logic                    exp_run,
    input  logic [16:0]             exp_recip
);

logic               test;
logic signed [26:0] n_metropolis;
exp #(
    .nbeta(dbeta * (id+1))
) exp (
    .clk     ( clk             ),
    .x       ( -delta_distance ),
    .y       ( n_metropolis    ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

assign test = (-delta_distance >= 0) || (n_metropolis > in_opt.r_metropolis[22:0]);

total_data_t                        write_data;
logic signed [$bits(out_data):0]    delta;
assign delta = $signed(delta_distance);
assign write_data  = ( distance_shift) ?        prev_data :
                     (command == PREV) ?        prev_data :
                     (command == FOLW) ?        folw_data :
                     (metropolis_run && test) ? self_data + delta : 
                     (metropolis_run) ?         self_data : 
                                                out_data;

always_ff @(posedge clk) begin
    out_data  <= write_data;
    out_opt.K <= in_opt.K;
    out_opt.L <= in_opt.L;
    out_opt.r_metropolis <= in_opt.r_metropolis;
    out_opt.r_exchange <= in_opt.r_exchange;
    if(in_opt.command == THR) begin
        out_opt.command <= THR;
    end else if(metropolis_run) begin
        if(test) begin
            if(in_opt.command == TWO) begin
                out_opt.command <= TWO;
            end else begin
                if(in_opt.K < in_opt.L) out_opt.command <= OR0;
                else                    out_opt.command <= OR1;
            end
        end else begin
            out_opt.command <= THR;
        end
    end    
end

endmodule