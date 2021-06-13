module replica
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic [base_log-1:0]     base_id,
    input  logic                    opt_run,
    input  opt_t                    opt,
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    input  total_data_t             self_data,

    input  logic                    exchange_shift_d, //   exchange_ex に ordering read/write コマンドを乗せる
    output exchange_command_t       exchange_ex,      // replica exchange test の結果を乗せる
    output exchange_command_t       exchange_mtr,     //   ordering read/write コマンドが乗ってない
    input  logic                    prev_exchange,    // 隣の test 結果を受け取る (replica_d)
    input  logic                    folw_exchange,    // 隣の test 結果を受け取る (replica_d)
    output logic                    out_exchange,     // 隣に test 結果を渡す     (replica)

    input  logic                    exp_init,
    input  logic                    exp_run,
    input  logic                    exp_fin,
    input  logic [16:0]             exp_recip
);

logic signed [31:0]      action;
logic signed [26:0]      n_exchange;
logic                    test;
exchange_command_t       exchange_l;

assign out_exchange = test;
assign exchange_ex  = (exchange_shift_d) ? PREV : exchange_l;
assign exchange_mtr = exchange_l;

exp #(
    .nbeta(dbeta),
    .step(0)
) exp (
    .clk     ( clk             ),
    .base_id ( base_id         ),
    .x       ( action[20:0]    ),
    .y       ( n_exchange      ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

always_comb begin
    if(opt.com == OR1) begin
        action = $signed(self_data - prev_data);
    end else begin
        action = $signed(folw_data - self_data);
    end
end

logic  replica_run;
assign replica_run = exp_fin && (opt.com != THR);
always_ff @(posedge clk) begin
    if(replica_run)
        test <= '0;
        //test <= (action * dbeta > -(8<<17)) && ((action >= 0) || (n_exchange > opt.r_exchange[22:0]));
        
    if(opt_run) begin
        if(opt.com == OR1)
            if((id == 0) || (id == replica_num-1))  exchange_l <= SELF;
            else if(~test)                          exchange_l <= SELF;
            else                                    exchange_l <= PREV;
        else if(opt.com == TWO)
            if(~test)                               exchange_l <= SELF;
            else                                    exchange_l <= FOLW;
        else                                        exchange_l <= NOP;
    end else                                        exchange_l <= NOP;
end
    
endmodule