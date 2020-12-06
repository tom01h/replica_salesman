module metropolis
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  exchange_command_t       command,
    input  logic                    exchange_valid,
    input  opt_t                    in_opt,
    output opt_t                    out_opt,
    input  delata_data_t            delta_distance,
    input  logic [31:0]             r_metropolis,
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    output total_data_t             out_data
);

real n_metropolis;
real random;
logic test;
assign n_metropolis = $exp(($itor(-delta_distance)/$itor(1<<17)) * $itor(id+1) * $itor(dbeta));
assign random = $itor(r_metropolis)/$itor(1<<16)/$itor(1<<16);
assign test = (delta_distance <= 0) || (n_metropolis > random);

total_data_t                        write_data;
logic signed [$bits(out_data):0]    delta;
assign delta = $signed(delta_distance);
assign write_data  = (command == PREV) ? prev_data :
                     (command == FOLW) ? folw_data :
                     (command == SELF && test) ? out_data + delta : 
                                         out_data;

always_ff @(posedge clk) begin
    out_data  <= write_data;
    out_opt.K <= in_opt.K;
    out_opt.L <= in_opt.L;
    if(~exchange_valid) begin
        out_opt.command <= THR;
    end else if(test) begin
        if(in_opt.command == TWO) begin
            out_opt.command <= in_opt.command;
        end else begin
            if(in_opt.K < in_opt.L) out_opt.command <= OR0;
            else                    out_opt.command <= OR1;
        end
    end else begin
        out_opt.command <= THR;
    end    
end

endmodule