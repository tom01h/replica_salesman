module exchange
    import replica_pkg::*;
#(
    parameter two_opt_node=0
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic [base_log-1:0]     base_id,
    input  exchange_command_t       command,
    input  opt_t                    opt,
    input  logic                    prev_valid,
    input  replica_data_t           prev_data,
    input  logic                    self_valid,
    input  replica_data_t           self_data,
    input  logic                    folw_valid,
    input  replica_data_t           folw_data,
    output logic                    out_valid,
    output replica_data_t           out_data,
    input  logic                    ordering_read,
    input  logic [city_num_log-1:0] ordering_addr,
    output logic [city_num_log-1:0] ordering_data,

    output exchange_command_t       out_ex_com,
    input  exchange_command_t       in_ex_com
);

logic               [city_div_log-1:0]  rcount,     wcount;
exchange_command_t                      command_d1, command_d2, command_d3;
opt_t                                   opt_d1;

assign out_ex_com = command_d3;

logic                                   out_valid_x;
replica_data_t                          out_data_r;
replica_data_t                          out_data_d;
replica_data_t                          out_data_x;

logic              write_valid;
replica_data_t     write_data;
assign write_valid = (in_ex_com == PREV) ? prev_valid :
                     (in_ex_com == FOLW) ? folw_valid :
                     (in_ex_com == SELF) ? self_valid  : '0;
assign write_data  = (in_ex_com == PREV) ? prev_data :
                     (in_ex_com == FOLW) ? folw_data : self_data;

logic               [city_div_log-1:0]  raddr_i;
logic               [2:0]               ordering_sel;
assign raddr_i = (ordering_read) ? ordering_addr[city_num_log-1:3] : rcount;
always_ff @(posedge clk) begin
    ordering_sel <= ordering_addr[2:0];
end
assign ordering_data = out_data_r[ordering_sel];

logic [replica_data_bit-1:0] ram [0:2**(city_div_log+base_log) -1];
always_ff @(posedge clk) begin
    if (write_valid) begin
        ram[{base_id, wcount}] <= write_data;
    end
    out_data_r <= ram[{base_id, raddr_i}];
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
    opt_d1     <= opt;
end

always_ff @(posedge clk) begin
    if (reset)                       wcount <= '0;
    else if (write_valid)
        if (wcount + 1 != city_div)  wcount <= wcount + 1;
        else                         wcount <= '0;
end    

generate
if(two_opt_node == 0)
opt_route_or opt_route
(
    .clk           ( clk           ),
    .reset         ( reset         ),
    .command       ( command       ),
    .command_nop_d ( command_nop_d ),
    .opt           ( opt           ),
    .rcount        ( rcount        ),
    .out_data_i    ( out_data_d    ),
    .out_valid_o   ( out_valid_x   ),
    .out_data_o    ( out_data_x    )
);
else
opt_route_two opt_route
(
    .clk           ( clk           ),
    .reset         ( reset         ),
    .command       ( command       ),
    .command_nop_d ( command_nop_d ),
    .opt           ( opt           ),
    .rcount        ( rcount        ),
    .out_data_i    ( out_data_d    ),
    .out_valid_o   ( out_valid_x   ),
    .out_data_o    ( out_data_x    )
);
endgenerate

endmodule