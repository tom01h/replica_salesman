module replica
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter two_opt_node = 0
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic                    opt_run,
    input  opt_t                    opt,
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    input  total_data_t             self_data,
    output total_data_t             out_data,

    input  logic                    exchange_shift_d, //   exchange_ex に ordering read/write コマンドを乗せる
    output exchange_command_t       exchange_ex,      // replica exchange test の結果を乗せる
    output logic                    exchange_mtr,     //   ordering read/write コマンドが乗ってない
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
assign exchange_mtr = (exchange_l != NOP);

exp #(
    .nbeta(dbeta),
    .step(0)
) exp (
    .clk     ( clk             ),
    .base_id ( opt.base_id     ),
    .x       ( action[20:0]    ),
    .y       ( n_exchange      ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

always_comb begin
    if(two_opt_node == 0) begin
        action = $signed(self_data - prev_data);
    end else begin
        action = $signed(folw_data - self_data);
    end
end

total_data_t             self_data_d;
total_data_t             prev_data_d;
total_data_t             folw_data_d;

always_ff @(posedge clk) begin
    if(opt_run) begin
        self_data_d <= self_data;
        prev_data_d <= prev_data;
        folw_data_d <= folw_data;
    end
end

logic  replica_run;
assign replica_run = exp_fin && (opt.com != THR);
always_ff @(posedge clk) begin
    if(replica_run)
        test <= (action * dbeta > -(8<<17)) && ((action >= 0) || (n_exchange > opt.r_exchange[22:0]));
        
    if(opt_run) begin
        if(opt.com == THR)                                exchange_l <= NOP;
        else if(two_opt_node)
            if(~test)                               begin exchange_l <= SELF; out_data <= self_data_d; end
            else                                    begin exchange_l <= FOLW; out_data <= folw_data_d; end
        else
            if((id == 0) && (opt.base_id == 0) || (id == node_num-1) && (opt.base_id == base_num-1))
                                                    begin exchange_l <= SELF; out_data <= self_data_d; end
            else if(~test)                          begin exchange_l <= SELF; out_data <= self_data_d; end
            else                                    begin exchange_l <= PREV; out_data <= prev_data_d; end
    end else                                        exchange_l <= NOP;
end
    
endmodule