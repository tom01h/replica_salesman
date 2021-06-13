module node
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                      clk,
    input  logic                      reset,
    
    input  logic [base_log-1:0]       base_id,
    
    input  logic                      random_init,       // set random seed
    input  logic [63:0]               random_seed,
    input  logic                      tp_dis_write,      // set 2点間距離
    input  logic [city_num_log*2-1:0] tp_dis_waddr,
    input  distance_data_t            tp_dis_wdata,
    input  logic                      distance_shift,    // total distance read/write
    input  logic                      exchange_shift_d,  // ordering read/write

    input  logic                      opt_run,           // opt run
    input  opt_command_t              opt_com,           // opt mode

    input  distance_command_t         or_distance_com,      // delta distance

    input  distance_command_t         tw_distance_com,      // delta distance

    input  total_data_t               or_prev_dis_data,     // for replica exchange test
    input  total_data_t               or_folw_dis_data,
    output total_data_t               or_out_dis_data,
    input  logic                      or_prev_exchange,     // for delta distance
    input  logic                      or_folw_exchange,
    output logic                      or_out_exchange,
    input  logic                      or_prev_ord_valid,    // for exchange ordering
    input  replica_data_t             or_prev_ord_data,
    input  logic                      or_folw_ord_valid,
    input  replica_data_t             or_folw_ord_data,
    output logic                      or_out_ord_valid,
    output replica_data_t             or_out_ord_data,

    input  total_data_t               tw_prev_dis_data,     // for replica exchange test
    input  total_data_t               tw_folw_dis_data,
    output total_data_t               tw_out_dis_data,
    input  logic                      tw_prev_exchange,     // for delta distance
    input  logic                      tw_folw_exchange,
    output logic                      tw_out_exchange,
    input  logic                      tw_prev_ord_valid,    // for exchange ordering
    input  replica_data_t             tw_prev_ord_data,
    input  logic                      tw_folw_ord_valid,
    input  replica_data_t             tw_folw_ord_data,
    output logic                      tw_out_ord_valid,
    output replica_data_t             tw_out_ord_data,

    input  logic                      exp_init,
    input  logic                      exp_run,
    input  logic                      exp_fin,
    input  logic [16:0]               exp_recip
);

total_data_t              or_self_dis_data;
logic                     or_self_ord_valid;
replica_data_t            or_self_ord_data;

total_data_t              tw_self_dis_data;
logic                     tw_self_ord_valid;
replica_data_t            tw_self_ord_data;

assign or_out_dis_data  = or_self_dis_data;
//assign or_out_exchange  = or_self_exchange;
assign or_out_ord_valid = or_self_ord_valid;
assign or_out_ord_data  = or_self_ord_data;

assign tw_out_dis_data  = tw_self_dis_data;
//assign tw_out_exchange  = tw_self_exchange;
assign tw_out_ord_valid = tw_self_ord_valid;
assign tw_out_ord_data  = tw_self_ord_data;

exchange_command_t         or_ex_com;
exchange_command_t         tw_ex_com;
exchange_command_t         exchange_mtr_or;
exchange_command_t         exchange_mtr_tw;

opt_t                      or_opt;
opt_t                      tw_opt;

random random
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .base_id         ( base_id         ),
    .run             ( opt_run         ),
    .opt_com         ( opt_com         ),
    .init            ( random_init     ),
    .i_seed          ( random_seed     ),
    .or_opt          ( or_opt          ),
    .tw_opt          ( tw_opt          ),
    .ready           (                 )
);

sub_node #(.id(id), .two_opt_node(0)) or_node (
    .clk              ( clk                 ),
    .reset            ( reset               ),
    
    .base_id          ( base_id             ),

    .tp_dis_write     ( tp_dis_write        ), // set 2点間距離
    .tp_dis_waddr     ( tp_dis_waddr        ),
    .tp_dis_wdata     ( tp_dis_wdata        ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_run          ( opt_run             ), // opt run
    .opt              ( or_opt              ), // opt mode
    
    .distance_com     ( or_distance_com     ), // delta distance

    .prev_dis_data    ( tw_prev_dis_data    ),
    .self_dis_data    ( tw_self_dis_data    ),
    .folw_dis_data    ( tw_folw_dis_data    ),
    .out_dis_data     ( or_self_dis_data    ),
    
    .prev_exchange    ( or_prev_exchange    ),
    .folw_exchange    ( or_folw_exchange    ),
    .out_exchange     ( or_out_exchange     ),

    .prev_ord_valid   ( tw_prev_ord_valid   ),
    .prev_ord_data    ( tw_prev_ord_data    ),
    .self_ord_valid   ( tw_self_ord_valid   ),
    .self_ord_data    ( tw_self_ord_data    ),
    .folw_ord_valid   ( tw_folw_ord_valid   ),
    .folw_ord_data    ( tw_folw_ord_data    ),
    .out_ord_valid    ( or_self_ord_valid   ),
    .out_ord_data     ( or_self_ord_data    ),

    .out_ex_com       ( or_ex_com           ),
    .in_ex_com        ( tw_ex_com           ),
    .exchange_mtr_i   ( exchange_mtr_tw     ),
    .exchange_mtr_o   ( exchange_mtr_or     ),

    .exp_init         ( exp_init            ),
    .exp_run          ( exp_run             ),
    .exp_fin          ( exp_fin             ),
    .exp_recip        ( exp_recip           )
);

sub_node #(.id(id), .two_opt_node(1)) two_node (
    .clk              ( clk                 ),
    .reset            ( reset               ),
    
    .base_id          ( base_id             ),

    .tp_dis_write     ( tp_dis_write        ), // set 2点間距離
    .tp_dis_waddr     ( tp_dis_waddr        ),
    .tp_dis_wdata     ( tp_dis_wdata        ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_run          ( opt_run             ), // opt run
    .opt              ( tw_opt              ), // opt mode
    
    .distance_com     ( tw_distance_com     ), // delta distance

    .prev_dis_data    ( or_prev_dis_data    ),
    .self_dis_data    ( or_self_dis_data    ),
    .folw_dis_data    ( or_folw_dis_data    ),
    .out_dis_data     ( tw_self_dis_data    ),
    
    .prev_exchange    ( tw_prev_exchange    ),
    .folw_exchange    ( tw_folw_exchange    ),
    .out_exchange     ( tw_out_exchange     ),

    .prev_ord_valid   ( or_prev_ord_valid   ),
    .prev_ord_data    ( or_prev_ord_data    ),
    .self_ord_valid   ( or_self_ord_valid   ),
    .self_ord_data    ( or_self_ord_data    ),
    .folw_ord_valid   ( or_folw_ord_valid   ),
    .folw_ord_data    ( or_folw_ord_data    ),
    .out_ord_valid    ( tw_self_ord_valid   ),
    .out_ord_data     ( tw_self_ord_data    ),

    .out_ex_com       ( tw_ex_com           ),
    .in_ex_com        ( or_ex_com           ),
    .exchange_mtr_i   ( exchange_mtr_or     ),
    .exchange_mtr_o   ( exchange_mtr_tw     ),

    .exp_init         ( exp_init            ),
    .exp_run          ( exp_run             ),
    .exp_fin          ( exp_fin             ),
    .exp_recip        ( exp_recip           )
);
endmodule