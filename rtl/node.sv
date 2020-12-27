module node
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      random_init,
    input  logic [63:0]               random_seed,
    input  logic                      random_run,
    input  distance_command_t         distance_com,
    input  logic                      metropolis_run,
    input  logic                      replica_run,
    input  logic                      exchange_run,
    input  exchange_command_t         c_exchange,
    input  logic                      shift_distance,
    input  opt_command_t              opt_command,
    input  logic                      exchange_valid,
    input  logic                      rbank,
    input  logic                      distance_write,
    input  logic [city_num_log*2-1:0] distance_w_addr,
    input  distance_data_t            distance_w_data,
    input  total_data_t               prev_dis_data,
    input  total_data_t               folw_dis_data,
    output total_data_t               out_dis_data,
    input  logic                      prev_exchange,
    input  logic                      folw_exchange,
    output logic                      out_exchange,
    input  logic                      prev_ord_valid,
    input  replica_data_t             prev_ord_data,
    input  logic                      folw_ord_valid,
    input  replica_data_t             folw_ord_data,
    output logic                      out_ord_valid,
    output replica_data_t             out_ord_data
);

opt_t                      opt;
opt_t                      opt_ex;
exchange_command_t         exchange_ex;
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
    .clk          ( clk          ),
    .reset        ( reset        ),
    .cmd          ( opt.command  ),
    .init         ( random_init  ),
    .i_seed       ( random_seed  ),
    .run          ( random_run   ),
    .ready        (              ),
    .K            ( K            ),
    .L            ( L            ),
    .r_metropolis ( r_metropolis ),
    .r_exchange   ( r_exchange   )
);

distance distance
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .command         ( distance_com    ),
    .opt             ( opt             ),
    .distance_write  ( distance_write  ),
    .distance_w_addr ( distance_w_addr ),
    .distance_w_data ( distance_w_data ),
    .ordering_read   ( ordering_read   ),
    .ordering_addr   ( ordering_addr   ),
    .ordering_data   ( ordering_data   ),
    .delta_distance  ( delta_distance  )
);    

metropolis #(.id(id)) metropolis
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .command         ( exchange_ex     ),
    .metropolis_run  ( metropolis_run  ),
    .shift_distance  ( shift_distance  ),
    .exchange_valid  ( exchange_valid  ),
    .in_opt          ( opt             ),
    .out_opt         ( opt_ex          ),
    .delta_distance  ( delta_distance  ),
    .r_metropolis    ( r_metropolis    ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .out_data        ( out_dis_data    )
);

generate
if(id[0] == 0)
replica #(.id(id), .replica_num(replica_num)) replica
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .exchange_valid  ( exchange_valid  ),
    .replica_run     ( replica_run     ),
    .exchange_run    ( exchange_run    ),
    .in_exchange     ( c_exchange      ),
    .exchange_ex     ( exchange_ex     ),
    .prev_exchange   ( prev_exchange   ),
    .folw_exchange   ( folw_exchange   ),
    .out_exchange    ( out_exchange    ),
    .opt_command     ( opt_command     ),
    .r_exchange      ( r_exchange      ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    )
);
else
replica_d #(.id(id), .replica_num(replica_num)) replica
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .exchange_valid  ( exchange_valid  ),
    .replica_run     ( replica_run     ),
    .exchange_run    ( exchange_run    ),
    .in_exchange     ( c_exchange      ),
    .exchange_ex     ( exchange_ex     ),
    .prev_exchange   ( prev_exchange   ),
    .folw_exchange   ( folw_exchange   ),
    .out_exchange    ( out_exchange    ),
    .opt_command     ( opt_command     ),
    .r_exchange      ( r_exchange      ),
    .prev_data       ( prev_dis_data   ),
    .folw_data       ( folw_dis_data   ),
    .self_data       ( out_dis_data    )
);
endgenerate

exchange exchange
(
    .clk           ( clk              ),
    .reset         ( reset            ),
    .command       ( exchange_ex      ),
    .opt           ( opt_ex           ),
    .rbank         ( rbank            ),
    .prev_valid    ( prev_ord_valid   ),
    .prev_data     ( prev_ord_data    ),
    .folw_valid    ( folw_ord_valid   ),
    .folw_data     ( folw_ord_data    ),
    .out_valid     ( out_ord_valid    ),
    .out_data      ( out_ord_data     ),
    .ordering_read ( ordering_read    ),
    .ordering_addr ( ordering_addr    ),
    .ordering_data ( ordering_data    )

);

endmodule