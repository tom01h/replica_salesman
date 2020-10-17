module replica
    import replica_pkg::*;
(
    input  logic              clk,
    input  logic              reset,
    input  exchange_command_t c_exchange,
    input  distance_command_t c_distance,
    input  opt_t              opt,
    input  logic              rbank,
    input  logic              prev_valid,
    input  replica_data_t     prev_data,
    input  logic              folw_valid,
    input  replica_data_t     folw_data,
    output logic              out_valid,
    output replica_data_t     out_data
);

distance distance
(
    .clk        ( clk        ),
    .reset      ( reset      ),
    .command    ( c_distance ),
    .opt        ( opt        )
);    

replica_ram replica_ram
(
    .clk        ( clk        ),
    .reset      ( reset      ),
    .command    ( c_exchange ),
    .opt        ( opt        ),
    .rbank      ( rbank      ),
    .prev_valid ( prev_valid ),
    .prev_data  ( prev_data  ),
    .folw_valid ( folw_valid ),
    .folw_data  ( folw_data  ),
    .out_valid  ( out_valid  ),
    .out_data   ( out_data   )
);

endmodule