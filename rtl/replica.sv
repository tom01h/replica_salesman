module replica
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
    input  logic                    exchange_shift_d,
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

real action;
real n_exchange;
real random;
logic test;
exchange_command_t       exchange_l;

assign out_exchange = test;
assign exchange_ex = (exchange_valid) ? exchange_l : (exchange_shift_d) ? PREV : NOP;

// id[0] == 0
always_comb begin
    if(opt_command == OR1) begin
        action = ($itor(self_data) - $itor(prev_data))/$itor(1<<17) * $itor(dbeta) ;
    end else begin
        action = ($itor(folw_data) - $itor(self_data))/$itor(1<<17) * $itor(dbeta) ;
    end
    n_exchange = $exp(action);
    random = r_exchange/$itor(1<<16)/$itor(1<<16);
end

always_ff @(posedge clk) begin
    if(replica_run)
        test <= (action >= 0) || (n_exchange > random);
        
    if(exchange_run) begin
        if(opt_command == OR1)
            if((id == 0) || (id == replica_num-1))  exchange_l <= SELF;
            else if(~test)                          exchange_l <= SELF;
            else                                    exchange_l <= PREV;
        else
            if(~test)                               exchange_l <= SELF;
            else                                    exchange_l <= FOLW;
    end else                                        exchange_l <= NOP;
end
    
endmodule