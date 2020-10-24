module metropolis
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  exchange_command_t       command,
    input  opt_t                    opt,
    input  delata_data_t            delta_distance,
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    output total_data_t             out_data
);

total_data_t             write_data;
assign write_data  = (command == PREV) ? prev_data :
                     (command == FOLW) ? folw_data :
                     (command == SELF && opt.command != THR) ? out_data + delta_distance : 
                                         out_data;

always_ff @(posedge clk) begin
    out_data  <= write_data;
end

endmodule