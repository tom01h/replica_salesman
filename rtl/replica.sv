module replica
    import replica_pkg::*;
(
    input  logic                      clk,
    input  logic                      reset,
    input  exchange_command_t         c_exchange,
    input  distance_command_t         c_distance,
    input  opt_t                      opt,
    input  logic                      rbank,
    input  logic                      distance_write,
    input  logic [city_num_log*2-1:0] distance_w_addr,
    input  distance_data_t            distance_w_data,
    input  logic                      prev_valid,
    input  replica_data_t             prev_data,
    input  logic                      folw_valid,
    input  replica_data_t             folw_data,
    output logic                      out_valid,
    output replica_data_t             out_data
);

logic                    ordering_read;
logic [city_num_log-1:0] ordering_addr;
logic [city_num_log-1:0] ordering_data;

distance distance
(
    .clk             ( clk             ),
    .reset           ( reset           ),
    .command         ( c_distance      ),
    .opt             ( opt             ),
    .distance_write  ( distance_write  ),
    .distance_w_addr ( distance_w_addr ),
    .distance_w_data ( distance_w_data ),
    .ordering_read   ( ordering_read   ),
    .ordering_addr   ( ordering_addr   ),
    .ordering_data   ( ordering_data   )
);    

exchange exchange
(
    .clk           ( clk           ),
    .reset         ( reset         ),
    .command       ( c_exchange    ),
    .opt           ( opt           ),
    .rbank         ( rbank         ),
    .prev_valid    ( prev_valid    ),
    .prev_data     ( prev_data     ),
    .folw_valid    ( folw_valid    ),
    .folw_data     ( folw_data     ),
    .out_valid     ( out_valid     ),
    .out_data      ( out_data      ),
    .ordering_read ( ordering_read ),
    .ordering_addr ( ordering_addr ),
    .ordering_data ( ordering_data )

);

endmodule