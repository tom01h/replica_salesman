module replica_d
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
    output logic                    out_exchange      // 隣に test 結果を渡す     (replica)
);

exchange_command_t       exchange_l;

assign out_exchange = (exchange_l != SELF);
assign exchange_ex  = (exchange_shift_d) ? PREV : exchange_l;
assign exchange_mtr = exchange_l;

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