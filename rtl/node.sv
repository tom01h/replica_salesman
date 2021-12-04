module node
    import replica_pkg::*;
#(
    parameter id = 0
)
(
    input  logic                      clk,
    input  logic                      reset,
    
    input  logic [base_log-1:0]       or_rn_base_id,
    input  logic [base_log-1:0]       tw_rn_base_id,
    input  logic [base_log-1:0]       or_dd_base_id,
    input  logic [base_log-1:0]       tw_dd_base_id,
    input  logic [base_log-1:0]       or_rp_base_id,
    input  logic [base_log-1:0]       tw_rp_base_id,
    input  logic [base_log-1:0]       or_ex_base_id,
    input  logic [base_log-1:0]       tw_ex_base_id,
    
    input  logic                      random_init,       // set random seed
    input  logic                      random_read,       // get random seed
    output logic                      random_ready,
    input  logic [63:0]               random_seed_w,
    output logic [63:0]               random_seed_r,
    input  logic                      tp_dis_write,      // set 2点間距離
    input  logic [city_num_log*2-2:0] tp_dis_waddr,
    input  distance_data_t            tp_dis_wdata,
    input  logic                      distance_shift,    // total distance read/write
    input  logic                      exchange_shift_d,  // ordering read/write

    input  logic                      opt_run,           // opt run
    input  logic                      or_opt_en,         // opt en
    input  logic                      tw_opt_en,         // opt en

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
    output total_data_t               minimum_distance,
    output exchange_command_t         minimum_ex_com,

    input  logic                      exp_init,
    input  logic                      exp_run,
    input  logic                      exp_fin,
    input  logic [16:0]               exp_recip
);

total_data_t              or_self_dis_data;
total_data_t              or_replica_data;
logic                     or_self_ord_valid;
replica_data_t            or_self_ord_data;

total_data_t              tw_self_dis_data;
total_data_t              tw_replica_data;
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
logic                      exchange_mtr_or;
logic                      exchange_mtr_tw;

opt_t                      or_opt;
opt_t                      tw_opt;

assign minimum_distance = tw_replica_data;
assign minimum_ex_com   = tw_ex_com;

random #(.id(id)) random
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .or_base_id      ( or_rn_base_id   ),
    .tw_base_id      ( tw_rn_base_id   ),
    .run             ( opt_run         ),
    .or_opt_en       ( or_opt_en       ),
    .tw_opt_en       ( tw_opt_en       ),
    .init            ( random_init     ),
    .read            ( random_read     ),
    .w_seed          ( random_seed_w   ),
    .r_seed          ( random_seed_r   ),
    .or_opt          ( or_opt          ),
    .tw_opt          ( tw_opt          ),
    .ready           ( random_ready    )
);

logic [city_num_log*2-2:0] or_distance_addr;
distance_data_t            or_distance_data;
logic [city_num_log*2-2:0] tw_distance_addr;
distance_data_t            tw_distance_data;

tp_distance_ram tp_distance_ram
(
    .clk              ( clk              ),
    .reset            ( reset            ),

    .tp_dis_write     ( tp_dis_write     ),
    .tp_dis_waddr     ( tp_dis_waddr     ),
    .tp_dis_wdata     ( tp_dis_wdata     ),

    .or_distance_addr ( or_distance_addr ),
    .or_distance_data ( or_distance_data ),

    .tw_distance_addr ( tw_distance_addr ),
    .tw_distance_data ( tw_distance_data )
);

sub_node #(.id(id), .two_opt_node(0)) or_node (
    .clk              ( clk                 ),
    .reset            ( reset               ),
    
    .dd_base_id       ( or_dd_base_id       ),
    .rp_base_id       ( or_rp_base_id       ),
    .ex_base_id_r     ( or_ex_base_id       ),
    .ex_base_id_w     ( tw_ex_base_id       ),

    .distance_addr    ( or_distance_addr    ), // two point distance
    .distance_data    ( or_distance_data    ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_run          ( opt_run             ), // opt run
    .opt              ( or_opt              ), // opt mode
    
    .distance_com     ( or_distance_com     ), // delta distance

    .prev_dis_data    ( or_prev_dis_data    ),
    .folw_dis_data    ( or_folw_dis_data    ),
    .out_dis_data     ( or_self_dis_data    ),
    .replica_data_i   ( tw_replica_data     ),
    .replica_data_o   ( or_replica_data     ),
    
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
    
    .dd_base_id       ( tw_dd_base_id       ),
    .rp_base_id       ( tw_rp_base_id       ),
    .ex_base_id_r     ( tw_ex_base_id       ),
    .ex_base_id_w     ( or_ex_base_id       ),

    .distance_addr    ( tw_distance_addr    ), // two point distance
    .distance_data    ( tw_distance_data    ),
    .distance_shift   ( distance_shift      ), // total distance read/write
    .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
    
    .opt_run          ( opt_run             ), // opt run
    .opt              ( tw_opt              ), // opt mode
    
    .distance_com     ( tw_distance_com     ), // delta distance

    .prev_dis_data    ( tw_prev_dis_data    ),
    .folw_dis_data    ( tw_folw_dis_data    ),
    .out_dis_data     ( tw_self_dis_data    ),
    .replica_data_i   ( or_replica_data     ),
    .replica_data_o   ( tw_replica_data     ),
    
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