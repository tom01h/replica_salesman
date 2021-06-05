module replica
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic                    replica_run,
    input  opt_command_t            opt_command,
    input  logic [31:0]             r_exchange,       // test 用のランダムデータ
    input  total_data_t             prev_data,
    input  total_data_t             folw_data,
    input  total_data_t             self_data,

    input  logic                    exchange_shift_d, //   exchange_ex に ordering read/write コマンドを乗せる
    input  logic                    exchange_run,     // このタイミングで exchange と metropolis 向けに
    output exchange_command_t       exchange_ex,      // このコマンドを作る replica exchange test の結果を乗せる
    output exchange_command_t       exchange_mtr,     //   ordering read/write コマンドが乗ってない
    input  logic                    prev_exchange,    // 隣の test 結果を受け取る (replica_d)
    input  logic                    folw_exchange,    // 隣の test 結果を受け取る (replica_d)
    output logic                    out_exchange,     // 隣に test 結果を渡す     (replica)

    input  logic                    exp_init,
    input  logic                    exp_run,
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
    .nbeta(dbeta)
) exp (
    .clk     ( clk             ),
    .x       ( action[20:0]    ),
    .y       ( n_exchange      ),
    .init    ( exp_init        ),
    .run     ( exp_run         ),
    .recip   ( exp_recip       )
);

always_comb begin
    if(opt_command == OR1) begin
        action = $signed(self_data - prev_data);
    end else begin
        action = $signed(folw_data - self_data);
    end
end

always_ff @(posedge clk) begin
    if(replica_run)
        test <= '0;
        
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