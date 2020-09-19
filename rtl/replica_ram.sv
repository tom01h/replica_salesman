module replica_ram
    import replica_pkg::*;
(
    input  logic             clk,
    input  logic             reset,
    input  replica_command_t command,
    input  opt_t             opt,
    input  logic             rbank,
    input  logic             prev_valid,
    input  replica_data_t    prev_data,
    input  logic             folw_valid,
    input  replica_data_t    folw_data,
    output logic             out_valid,
    output replica_data_t    out_data
);

logic               [city_num-1:0]  rcount,     wcount;
replica_command_t                   command_d1, command_d2, command_d3;
logic                               wbank_d1,   wbank_d2,   wbank_d3;
opt_t                               opt_d1,     opt_d2;

logic                               out_valid_x;
replica_data_t                      out_data_r;
replica_data_t                      out_data_d;
replica_data_t                      out_data_x;

logic                               write_valid;
replica_data_t                      write_data;
assign write_valid = (command_d3 == PREV) ? prev_valid :
                     (command_d3 == FOLW) ? folw_valid :
                     (command_d3 == SELF) ? out_valid  : '0;
assign write_data  = (command_d3 == PREV) ? prev_data :
                     (command_d3 == FOLW) ? folw_data : out_data;

replica_data_t [1:0][city_num-1:0]  ram;
always_ff @(posedge clk) begin
    if (write_valid) begin
        ram[wbank_d3][wcount] <= write_data;
    end
    out_data_r <= ram[rbank][rcount];
end

always_ff @(posedge clk) begin
    out_valid <= out_valid_x;
    out_data  <= out_data_x;
end

logic command_nop_d;
always_ff @(posedge clk) begin
    out_data_d <= out_data_r;
    if (command != NOP)
        command_d1 <= command;
    command_d2 <= command_d1;
    command_d3 <= command_d2;
    command_nop_d <= (command == NOP);
    wbank_d1   <= ~rbank;
    wbank_d2   <= wbank_d1;
    wbank_d3   <= wbank_d2;
    opt_d1     <= opt;
    opt_d2     <= opt_d1;
end

always_ff @(posedge clk) begin
    if (reset)                        wcount <= '0;
    else if (write_valid)
        if (wcount + 1 != city_num)   wcount <= wcount + 1;
        else                          wcount <= '0;
end    

opt_route opt_route
(
    .clk           ( clk           ),
    .reset         ( reset         ),
    .command       ( command       ),
    .command_nop_d ( command_nop_d ),
    .opt           ( opt_d2        ),
    .rcount        ( rcount        ),
    .out_data_i    ( out_data_d    ),
    .out_valid_o   ( out_valid_x   ),
    .out_data_o    ( out_data_x    )
);

endmodule