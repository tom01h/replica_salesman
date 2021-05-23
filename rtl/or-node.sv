module or-node
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                      clk,
    input  logic                      reset,
    
    input  logic                      random_init,       // set random seed
    input  logic [63:0]               random_seed,
    input  logic                      tp_dis_write,      // set 2点間距離
    input  logic [city_num_log*2-1:0] tp_dis_waddr,
    input  distance_data_t            tp_dis_wdata,
    input  logic                      distance_shift,    // total distance read/write
    input  logic                      exchange_shift_d,  // ordering read/write

    input  opt_command_t              opt_command,       // opt mode

    input  logic                      random_run,        // random
    input  distance_command_t         distance_com,      // delta distance
    input  logic                      metropolis_run,    // metropolis test
    input  logic                      replica_run,       // replica exchange test
    input  logic                      exchange_run,      // chenge ordering & replica exchange

    input  logic                      exchange_bank,

    input  total_data_t               prev_dis_data,     // for replica exchange test
    input  total_data_t               folw_dis_data,
    output total_data_t               out_dis_data,
    input  logic                      prev_exchange,     // for delta distance
    input  logic                      folw_exchange,
    output logic                      out_exchange,
    input  logic                      prev_ord_valid,    // for exchange ordering
    input  replica_data_t             prev_ord_data,
    input  logic                      folw_ord_valid,
    input  replica_data_t             folw_ord_data,
    output logic                      out_ord_valid,
    output replica_data_t             out_ord_data,

    input  logic                      exp_init,
    input  logic                      exp_run,
    input  logic [16:0]               exp_recip
);

opt_t                      opt;
opt_t                      opt_ex;
exchange_command_t         exchange_ex;
exchange_command_t         exchange_mtr;
logic [6:0]                K;
logic [6:0]                L;
logic [31:0]               r_metropolis;
logic [31:0]               r_exchange;
assign opt.command = opt_command;
assign opt.K       = K;
assign opt.L       = L;

logic                      ordering_read;
logic [city_num_log-1:0]   ordering_addr;
logic [city_num_log-1:0]   ordering_data;

delata_data_t              delta_distance;

random random
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .cmd             ( opt.command     ),
    .init            ( random_init     ),
    .i_seed          ( random_seed     ),
    .run             ( random_run      ),
    .ready           (                 ),
    .K               ( K               ),
    .L               ( L               ),
    .r_metropolis    ( r_metropolis    ),
    .r_exchange      ( r_exchange      )
);

distance distance
(
    .clk             ( clk             ),
    .reset           ( reset           ),

    .tp_dis_write    ( tp_dis_write    ),
    .tp_dis_waddr    ( tp_dis_waddr    ),
    .tp_dis_wdata    ( tp_dis_wdata    ),

    .command         ( distance_com    ),
    .opt             ( opt             ),
    .delta_distance  ( delta_distance  ),
    .ordering_read   ( ordering_read   ), // ordering メモリを読む
    .ordering_addr   ( ordering_addr   ),
    .ordering_data   ( ordering_data   )
);    

metropolis #(.id(id)) metropolis
(
    .clk             ( clk             ),
    .reset           ( reset           ),

    .distance_shift  ( distance_shift  ),

    .metropolis_run  ( metropolis_run  ),
    .in_opt          ( opt             ),
    .out_opt         ( opt_ex          ),
    .delta_distance  ( delta_distance  ),
    .r_metropolis    ( r_metropolis    ), // test 用のランダムデータ

    .command         ( exchange_mtr    ), // replica exchange test の結果を見て total distance を交換
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .out_data        ( out_dis_data    ),

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_recip       ( exp_recip       )
);

generate
if(id[0] == 0)
replica #(.id(id), .replica_num(replica_num)) replica
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    
    .replica_run     ( replica_run     ),
    .opt_command     ( opt_command     ),
    .r_exchange      ( r_exchange      ), // test 用のランダムデータ
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    ),
    
    .exchange_shift_d( exchange_shift_d), //   exchange_ex に ordering read/write コマンドを乗せる
    .exchange_run    ( exchange_run    ), // このタイミングで exchange と metropolis 向けに
    .exchange_ex     ( exchange_ex     ), // このコマンドを作る replica exchange test の結果を乗せる
    .exchange_mtr    ( exchange_mtr    ), //   ordering read/write コマンドが乗ってない
    .prev_exchange   ( prev_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .folw_exchange   ( folw_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .out_exchange    ( out_exchange    ), // 隣に test 結果を渡す     (replica)

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_recip       ( exp_recip       )
);
else    // replica test は 2ノードに1個で良いので test 結果を隣から受け取る
replica_d #(.id(id), .replica_num(replica_num)) replica
(
    .clk             ( clk             ),
    .reset           ( reset           ),

    .replica_run     ( replica_run     ),
    .opt_command     ( opt_command     ),
    .r_exchange      ( r_exchange      ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    ),

    .exchange_shift_d( exchange_shift_d), //   exchange_ex に ordering read/write コマンドを乗せる
    .exchange_run    ( exchange_run    ), // このタイミングで exchange と metropolis 向けに
    .exchange_ex     ( exchange_ex     ), // このコマンドを作る replica exchange test の結果を乗せる
    .exchange_mtr    ( exchange_mtr    ), //   ordering read/write コマンドが乗ってない
    .prev_exchange   ( prev_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .folw_exchange   ( folw_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .out_exchange    ( out_exchange    ), // 隣に test 結果を渡す     (replica)

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_recip       ( exp_recip       )

);
endgenerate

exchange #(.or-node('b1)) exchange
(
    .clk             ( clk              ),
    .reset           ( reset            ),
    .command         ( exchange_ex      ), // このコマンドで動く コマンドは replica で exchange_run から生成
    .opt             ( opt_ex           ), // ordering 変更規則 動作開始は command 入力の時
    .exchange_bank   ( exchange_bank    ),
    .prev_valid      ( prev_ord_valid   ),
    .prev_data       ( prev_ord_data    ),
    .folw_valid      ( folw_ord_valid   ),
    .folw_data       ( folw_ord_data    ),
    .out_valid       ( out_ord_valid    ),
    .out_data        ( out_ord_data     ),
    .ordering_read   ( ordering_read    ), // delta distance 計算用の IF
    .ordering_addr   ( ordering_addr    ),
    .ordering_data   ( ordering_data    )

);

endmodule