module sub_node
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter two_opt_node = 0
)
(
    input  logic                      clk,
    input  logic                      reset,
    
    input  logic [base_log-1:0]       base_id,
    
    input  logic                      tp_dis_write,      // set 2点間距離
    input  logic [city_num_log*2-1:0] tp_dis_waddr,
    input  distance_data_t            tp_dis_wdata,
    input  logic                      distance_shift,    // total distance read/write
    input  logic                      exchange_shift_d,  // ordering read/write

    input  logic                      opt_run,           // opt run
    input  opt_t                      opt,               // opt mode

    input  distance_command_t         distance_com,      // delta distance

    input  total_data_t               prev_dis_data,     // for replica exchange test
    input  total_data_t               self_dis_data,
    input  total_data_t               folw_dis_data,
    output total_data_t               out_dis_data,
    input  logic                      prev_exchange,     // for delta distance
    input  logic                      folw_exchange,
    output logic                      out_exchange,
    input  logic                      prev_ord_valid,    // for exchange ordering
    input  replica_data_t             prev_ord_data,
    input  logic                      self_ord_valid,
    input  replica_data_t             self_ord_data,
    input  logic                      folw_ord_valid,
    input  replica_data_t             folw_ord_data,
    output logic                      out_ord_valid,
    output replica_data_t             out_ord_data,

    output exchange_command_t         out_ex_com,
    input  exchange_command_t         in_ex_com,
    input  exchange_command_t         exchange_mtr_i,
    output exchange_command_t         exchange_mtr_o,

    input  logic                      exp_init,
    input  logic                      exp_run,
    input  logic                      exp_fin,
    input  logic [16:0]               exp_recip
);

opt_t                      opt_dis;
opt_t                      opt_ex;
opt_t                      opt_rep;

exchange_command_t         exchange_ex;

logic                      ordering_read;
logic [city_num_log-1:0]   ordering_addr;
logic [city_num_log-1:0]   ordering_data;

delata_data_t              delta_distance;

distance distance
(
    .clk             ( clk             ),
    .reset           ( reset           ),

    .tp_dis_write    ( tp_dis_write    ),
    .tp_dis_waddr    ( tp_dis_waddr    ),
    .tp_dis_wdata    ( tp_dis_wdata    ),

    .opt_run         ( opt_run         ),
    .in_opt          ( opt             ),
    .out_opt         ( opt_dis         ),
    .command         ( distance_com    ),

    .delta_distance  ( delta_distance  ),
    .ordering_read   ( ordering_read   ), // ordering メモリを読む
    .ordering_addr   ( ordering_addr   ),
    .ordering_data   ( ordering_data   )
);    

metropolis #(.id(id)) metropolis
(
    .clk             ( clk             ),
    .reset           ( reset           ),

    .base_id         ( base_id         ),
    .distance_shift  ( distance_shift  ),

    .opt_run         ( opt_run         ),
    .in_opt          ( opt_dis         ),
    .opt_rep         ( opt_rep         ),
    .opt_ex          ( opt_ex          ),
    .delta_distance  ( delta_distance  ),

    .command         ( exchange_mtr_i  ), // replica exchange test の結果を見て total distance を交換
    .prev_data       ( prev_dis_data   ),
    .self_data       ( self_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .out_data        ( out_dis_data    ),

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_fin         ( exp_fin         ),
    .exp_recip       ( exp_recip       )
);

generate
if(id[0] == 0)
replica #(.id(id)) replica (
    .clk             ( clk             ),
    .reset           ( reset           ),
    
    .base_id         ( base_id         ),
    .opt_run         ( opt_run         ),
    .opt             ( opt_rep         ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    ),
    
    .exchange_shift_d( exchange_shift_d), //   exchange_ex に ordering read/write コマンドを乗せる
    .exchange_ex     ( exchange_ex     ), // replica exchange test の結果を乗せる
    .exchange_mtr    ( exchange_mtr_o  ), //   ordering read/write コマンドが乗ってない
    .prev_exchange   ( prev_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .folw_exchange   ( folw_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .out_exchange    ( out_exchange    ), // 隣に test 結果を渡す     (replica)

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_fin         ( exp_fin         ),
    .exp_recip       ( exp_recip       )
);
else    // replica test は 2ノードに1個で良いので test 結果を隣から受け取る
replica_d #(.id(id)) replica (
    .clk             ( clk             ),
    .reset           ( reset           ),

    .base_id         ( base_id         ),
    .opt_run         ( opt_run         ),
    .opt             ( opt_rep         ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    ),

    .exchange_shift_d( exchange_shift_d), //   exchange_ex に ordering read/write コマンドを乗せる
    .exchange_ex     ( exchange_ex     ), // replica exchange test の結果を乗せる
    .exchange_mtr    ( exchange_mtr_o  ), //   ordering read/write コマンドが乗ってない
    .prev_exchange   ( prev_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .folw_exchange   ( folw_exchange   ), // 隣の test 結果を受け取る (replica_d)
    .out_exchange    ( out_exchange    ), // 隣に test 結果を渡す     (replica)

    .exp_init        ( exp_init        ),
    .exp_run         ( exp_run         ),
    .exp_fin         ( exp_fin         ),
    .exp_recip       ( exp_recip       )

);
endgenerate

exchange #(.two_opt_node(two_opt_node)) exchange
(
    .clk             ( clk              ),
    .reset           ( reset            ),
    .base_id         ( base_id          ),
    .command         ( exchange_ex      ), // このコマンドで動く コマンドは replica で exchange_run から生成
    .opt             ( opt_ex           ), // ordering 変更規則 動作開始は command 入力の時
    .prev_valid      ( prev_ord_valid   ),
    .prev_data       ( prev_ord_data    ),
    .self_valid      ( self_ord_valid   ),
    .self_data       ( self_ord_data    ),
    .folw_valid      ( folw_ord_valid   ),
    .folw_data       ( folw_ord_data    ),
    .out_valid       ( out_ord_valid    ),
    .out_data        ( out_ord_data     ),
    .ordering_read   ( ordering_read    ), // delta distance 計算用の IF
    .ordering_addr   ( ordering_addr    ),
    .ordering_data   ( ordering_data    ),

    .out_ex_com      ( out_ex_com       ),
    .in_ex_com       ( in_ex_com        )
);

endmodule