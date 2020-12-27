module replica_d
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    exchange_valid,
    input  logic                    replica_run,
    input  logic                    exchange_run,
    input  exchange_command_t       in_exchange,
    output exchange_command_t       exchange_ex,
    input  logic                    prev_exchange,
    input  logic                    folw_exchange,
    output logic                    out_exchange,
    input  opt_command_t            opt_command,
    input  logic [31:0]             r_exchange,
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    input  total_data_t             self_data
);

exchange_command_t       exchange_l;

assign out_exchange = (exchange_l != SELF);
assign exchange_ex = (~exchange_valid) ? in_exchange : exchange_l;

always_ff @(posedge clk) begin
    if(exchange_run) begin
        if(opt_command == OR1)
            if((id == 0) || (id == replica_num-1))  exchange_l <= SELF;
            else if(~folw_exchange)                 exchange_l <= SELF;
            else                                    exchange_l <= FOLW;
        else
            if(~prev_exchange)                      exchange_l <= SELF;
            else                                    exchange_l <= PREV;
    end else                                        exchange_l <= NOP;
end

endmodule