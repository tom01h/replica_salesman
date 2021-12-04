module distance
    import replica_pkg::*;
(
    input  logic                      clk,
    input  logic                      reset,
    
    output logic [city_num_log*2-2:0] distance_addr,
    input  distance_data_t            distance_data,

    input  logic                      opt_run,
    input  opt_t                      in_opt,
    output opt_t                      out_opt,
    input  distance_command_t         command,

    output delata_data_t              delta_distance,
    output logic [city_num_log-1:0]   ordering_addr,
    input  logic [city_num_log-1:0]   ordering_data
);

always_ff @(posedge clk)begin
    if(reset)        out_opt.com <= THR;
    else if(opt_run) out_opt     <= in_opt;
end

distance_op_t            command_op_i;
always_ff @(posedge clk) begin
    if(out_opt.com == THR) command_op_i <= DNOP;
    else                   command_op_i <= command.op;
    case(command.select)
        KN : ordering_addr <= out_opt.K;
        KP : ordering_addr <= out_opt.K + 1;
        KM : ordering_addr <= out_opt.K - 1;
        LN : ordering_addr <= out_opt.L;
        LP : ordering_addr <= out_opt.L + 1;
        LM : ordering_addr <= out_opt.L - 1;
        default : ordering_addr <= out_opt.K;
    endcase
end

distance_op_t            command_op;
always_ff @(posedge clk) begin
    command_op <= command_op_i;
end

logic [city_num_log-1:0] ordering_data_l;
distance_op_t            command_op_l;
always_ff @(posedge clk) begin
    ordering_data_l <= ordering_data;
    command_op_l <= command_op;
end

logic [city_num_log*2-1:0] ordering_data2_l;
logic [city_num_log-1:0]   ordering_data_d;
distance_op_t              command_op_d;
always_ff @(posedge clk) begin
    ordering_data2_l <= ordering_data_l * (ordering_data_l-1);
    ordering_data_d <= ordering_data_l;
    command_op_d <= command_op_l;
end

logic                      is_gt_d;
logic [city_num_log*2-1:0] ordering_data2_d;
logic [city_num_log-1:0]   offset;
distance_op_t              command_op_d2;
always_ff @(posedge clk) begin
    if(ordering_data_d > ordering_data_l) begin
        is_gt_d <= '1;
        offset <= ordering_data_l;
    end else begin
        is_gt_d <= '0;
        offset <= ordering_data_d;
    end    
    ordering_data2_d <= ordering_data2_l;
    command_op_d2 <= command_op_d;
end

logic                      distance_read;
assign distance_read = (command_op_d2 != DNOP) && (command_op_d2 != ZERO);
always_ff @(posedge clk) begin
    if(is_gt_d) distance_addr <= ordering_data2_d/2 + offset;
    else        distance_addr <= ordering_data2_l/2 + offset;
end

distance_op_t       command_op_d3;
always_ff @(posedge clk) begin
    command_op_d3 <= command_op_d2;
end

distance_data_t     distance_data_l;
distance_op_t       command_op_d4;
always_ff @(posedge clk) begin
    distance_data_l <= distance_data;
    command_op_d4 <= command_op_d3;
end

always_ff @(posedge clk) begin
    case(command_op_d4)
        ZERO: delta_distance <= '0;
        PLS : delta_distance <= delta_distance + distance_data_l;
        MNS : delta_distance <= delta_distance - distance_data_l;
    endcase
end

endmodule

module tp_distance_ram
    import replica_pkg::*;
(
    input  logic                      clk,
    input  logic                      reset,

    input  logic                      tp_dis_write,
    input  logic [city_num_log*2-2:0] tp_dis_waddr,
    input  distance_data_t            tp_dis_wdata,

    input  logic [city_num_log*2-2:0] or_distance_addr,
    output distance_data_t            or_distance_data,

    input  logic [city_num_log*2-2:0] tw_distance_addr,
    output distance_data_t            tw_distance_data
);

logic [city_num_log*2-2:0] or_distance_addr_w;
distance_data_t [1:0]      or_distance_data_w;
distance_data_t [1:0]      tw_distance_data_w;

logic                      or_distance_sel;
logic                      tw_distance_sel;

distance_data_t ram0 [0:4096-1];
distance_data_t ram1 [0:(city_num+1)*city_num/2-4096-1];

assign or_distance_data = or_distance_data_w[or_distance_sel];
assign tw_distance_data = tw_distance_data_w[tw_distance_sel];

assign or_distance_addr_w = (tp_dis_write) ? tp_dis_waddr : or_distance_addr;

always_ff @(posedge clk) begin
    or_distance_sel <= or_distance_addr_w[city_num_log*2-2];
    tw_distance_sel <= tw_distance_addr[city_num_log*2-2];
end

always_ff @(posedge clk) begin
    if(tp_dis_write & ~or_distance_addr_w[city_num_log*2-2])
        ram0[or_distance_addr_w[city_num_log*2-3:0]] <= tp_dis_wdata;
    or_distance_data_w[0] <= ram0[or_distance_addr_w[city_num_log*2-3:0]];
end
always_ff @(posedge clk) begin
    if(tp_dis_write &  or_distance_addr_w[city_num_log*2-2])
        ram1[or_distance_addr_w[city_num_log*2-4:0]] <= tp_dis_wdata;
    or_distance_data_w[1] <= ram1[or_distance_addr_w[city_num_log*2-4:0]];
end
always_ff @(posedge clk) begin
    tw_distance_data_w[0] <= ram0[tw_distance_addr[city_num_log*2-3:0]];
end
always_ff @(posedge clk) begin
    tw_distance_data_w[1] <= ram1[tw_distance_addr[city_num_log*2-4:0]];
end

endmodule