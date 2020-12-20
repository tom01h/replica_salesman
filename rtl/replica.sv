module replica
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

real action;
real n_exchange;
real random;
logic test;
assign out_exchange = test;

// id[0] == 0
always_comb begin
    if(opt_command == OR1) begin
        action = ($itor(self_data) - $itor(prev_data))/$itor(1<<17) * $itor(dbeta) ;
    end else begin
        action = ($itor(folw_data) - $itor(self_data))/$itor(1<<17) * $itor(dbeta) ;
    end
    n_exchange = $exp(action);
    random = r_exchange/$itor(1<<16)/$itor(1<<16);
    test = (action >= 0) || (n_exchange > random);

    if(~en)                                     exchange_ex = in_exchange;
    else if(opt_command == OR1)
        if((id == 0) || (id == replica_num-1))  exchange_ex = SELF;
        else if(~test)                          exchange_ex = SELF;
        else                                    exchange_ex = PREV;
    else
        if(~test)                               exchange_ex = SELF;
        else                                    exchange_ex = FOLW;
end

endmodule