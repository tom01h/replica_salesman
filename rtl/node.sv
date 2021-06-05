module node
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

    input  distance_command_t         or_distance_com,      // delta distance
    input  logic                      or_metropolis_run,    // metropolis test
    input  logic                      or_replica_run,       // replica exchange test
    input  logic                      or_exchange_run,      // chenge ordering & replica exchange

    input  distance_command_t         tw_distance_com,      // delta distance
    input  logic                      tw_metropolis_run,    // metropolis test
    input  logic                      tw_replica_run,       // replica exchange test
    input  logic                      tw_exchange_run,      // chenge ordering & replica exchange

    input  logic                      exchange_bank,

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
    
logic [6:0]                K;
logic [6:0]                L;
logic [31:0]               r_metropolis;
logic [31:0]               r_exchange;

or_node #(.id(id), .replica_num(replica_num)) or_node
(
    .clk              ( clk                 ),
    .reset            ( reset               ),
    
    .random_init      ( random_init         ), // set random seed
    .random_seed      ( random_seed         ),
    .tp_dis_write     ( tp_dis_write        ), // set 2点間距離
    .tp_dis_waddr     ( tp_dis_waddr        ),
    .tp_dis_wdata     ( tp_dis_wdata        ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_command      ( opt_command         ), // opt mode
    
    .random_run       ( random_run          ), // random
    .distance_com     ( or_distance_com     ), // delta distance
    .metropolis_run   ( or_metropolis_run   ), // metropolis test
    .replica_run      ( or_replica_run      ), // replica exchange test
    .exchange_run     ( or_exchange_run     ), // chenge ordering & replica exchange

    .exchange_bank    ( exchange_bank       ),

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

    .out_ex_com      ( or_ex_com            ),
    .in_ex_com       ( tw_ex_com            ),

.K            ( K            ),
.L            ( L            ),
.r_metropolis ( r_metropolis ),
.r_exchange   ( r_exchange   ),

    .exp_init         ( exp_init            ),
    .exp_run          ( exp_run             ),
    .exp_recip        ( exp_recip           )
);

two_node #(.id(id), .replica_num(replica_num)) two_node
(
    .clk              ( clk                 ),
    .reset            ( reset               ),
    
    .random_init      ( 1'b0       ), // set random seed
    .random_seed      ( 64'b0      ),
    .tp_dis_write     ( tp_dis_write        ), // set 2点間距離
    .tp_dis_waddr     ( tp_dis_waddr        ),
    .tp_dis_wdata     ( tp_dis_wdata        ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_command      ( opt_command         ), // opt mode
    
    .random_run       ( 1'b0      ), // random
    .distance_com     ( tw_distance_com     ), // delta distance
    .metropolis_run   ( tw_metropolis_run   ), // metropolis test
    .replica_run      ( tw_replica_run      ), // replica exchange test
    .exchange_run     ( tw_exchange_run     ), // chenge ordering & replica exchange

    .exchange_bank    ( exchange_bank       ),

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

    .out_ex_com      ( tw_ex_com            ),
    .in_ex_com       ( or_ex_com            ),

.K            ( K            ),
.L            ( L            ),
.r_metropolis ( r_metropolis ),
.r_exchange   ( r_exchange   ),

    .exp_init         ( exp_init            ),
    .exp_run          ( exp_run             ),
    .exp_recip        ( exp_recip           )
);
endmodule