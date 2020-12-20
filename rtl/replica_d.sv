module replica_d
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                    clk,
    input  logic                    reset,
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

logic en;
assign en = (in_exchange != NOP) && (opt_command != THR);
assign out_exchange = (exchange_ex != SELF);

always_comb begin
    if(~en)                                     exchange_ex = in_exchange;
    else if(opt_command == OR1)
        if((id == 0) || (id == replica_num-1))  exchange_ex = SELF;
        else if(~folw_exchange)                 exchange_ex = SELF;
        else                                    exchange_ex = FOLW;
    else
        if(~prev_exchange)                      exchange_ex = SELF;
        else                                    exchange_ex = PREV;
end

endmodule