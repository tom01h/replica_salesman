module exchange
    import replica_pkg::*;
#(
    parameter two_opt_node=0
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic [base_log-1:0]     dd_base_id,
    input  logic [base_log-1:0]     ex_base_id_r,
    input  logic [base_log-1:0]     ex_base_id_w,
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
    input  logic [city_num_log-1:0] ordering_addr,
    output logic [city_num_log-1:0] ordering_data,

    output exchange_command_t       out_ex_com,
    input  exchange_command_t       in_ex_com
);

logic               [city_div_log-1:0]  rcount,     wcount;
exchange_command_t                      command_d1, command_d2, command_d3;

assign out_ex_com = command_d3;

logic                                   out_valid_x;
replica_data_t                          out_data_r;
replica_data_t                          out_data_dis;
replica_data_t                          out_data_d;
replica_data_t                          out_data_x;

logic              write_valid;
replica_data_t     write_data;
assign write_valid = (in_ex_com == PREV) ? prev_valid :
                     (in_ex_com == FOLW) ? folw_valid :
                     (in_ex_com == SELF) ? self_valid : '0;
assign write_data  = (in_ex_com == PREV) ? prev_data :
                     (in_ex_com == FOLW) ? folw_data : self_data;

logic               [city_div_log-1:0]  raddr_i;
logic               [2:0]               ordering_sel;
assign raddr_i = ordering_addr[city_num_log-1:3];
always_ff @(posedge clk) begin
    ordering_sel <= ordering_addr[2:0];
end
assign ordering_data = out_data_dis[ordering_sel];

logic [base_log-1:0]     ex_base_id_w1, ex_base_id_w2, ex_base_id_w3;
always_ff @(posedge clk) begin
    ex_base_id_w1 <= ex_base_id_w;
    ex_base_id_w2 <= ex_base_id_w1;
    ex_base_id_w3 <= ex_base_id_w2;
end

logic [replica_data_bit-1:0]      ram0 [0:2**(city_div_log+base_log) -2];
logic [replica_data_bit-1:0]      ram1 [0:2**(city_div_log+base_log) -2];
replica_data_t                    out_data_0;
replica_data_t                    out_data_1;
logic [base_log+city_div_log-2:0] ram_addr_0;
logic [base_log+city_div_log-2:0] ram_addr_1;
logic                             write_valid0;
logic                             write_valid1;
logic                             ram_addr_sel;
assign write_valid0 = write_valid & (ex_base_id_w3[0] == 1'b0);
assign write_valid1 = write_valid & (ex_base_id_w3[0] == 1'b1);
assign ram_addr_0 = (ex_base_id_r[0] == 1'b0) ? {ex_base_id_r[base_log-1:1], rcount} : {dd_base_id[base_log-1:1], raddr_i};
assign ram_addr_1 = (ex_base_id_r[0] == 1'b1) ? {ex_base_id_r[base_log-1:1], rcount} : {dd_base_id[base_log-1:1], raddr_i};
always_ff @(posedge clk)
    ram_addr_sel <= ex_base_id_r[0];
assign out_data_r   = (ram_addr_sel == 1'b0) ? out_data_0 : out_data_1;
assign out_data_dis = (ram_addr_sel == 1'b1) ? out_data_0 : out_data_1;
    
always_ff @(posedge clk) begin
    if (write_valid0)
        ram0[{ex_base_id_w3[base_log-1:1], wcount}] <= write_data;
    out_data_0 <= ram0[ram_addr_0];
end
always_ff @(posedge clk) begin
    if (write_valid1)
        ram1[{ex_base_id_w3[base_log-1:1], wcount}] <= write_data;
    out_data_1 <= ram1[ram_addr_1];
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