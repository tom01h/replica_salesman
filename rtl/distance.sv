module distance
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  distance_command_t       command,
    input  opt_t                    opt,
    output logic                    ordering_read,
    output logic [city_num_log-1:0] ordering_addr,
    // input  logic [city_num_log-1:0] ordering_data
    output logic signed [20:0]      delta_distance
);

distance_op_t            command_op_i;
always_ff @(posedge clk) begin
    ordering_read <= (command.op != DNOP);
    command_op_i <= command.op;
    case(command.select)
        K  : ordering_addr <= opt.K;
        KP : ordering_addr <= opt.K + 1;
        KM : ordering_addr <= opt.K - 1;
        L  : ordering_addr <= opt.L;
        LP : ordering_addr <= opt.L + 1;
        LM : ordering_addr <= opt.L - 1;
        default : ordering_addr <= opt.K;
    endcase
end

logic [city_num_log-1:0] ordering_data; // dummy
distance_op_t            command_op;
always_ff @(posedge clk) begin
    ordering_data <= ordering_addr; // dummy
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

logic [city_num_log*2-1:0] distance_addr;
logic                      distance_read;
assign distance_read = (command_op_d2 != DNOP) && (command_op_d2 != ZERO);
always_ff @(posedge clk) begin
    if(is_gt_d) distance_addr <= ordering_data2_d/2 + offset;
    else        distance_addr <= ordering_data2_l/2 + offset;
end

logic [17:0]        distance_data;
distance_op_t       command_op_d3;
always_ff @(posedge clk) begin
    distance_data <= distance_addr;  // dummy
    command_op_d3 <= command_op_d2;
end

logic [17:0]        distance_data_l;
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

// logic [(city_num-1)*city_num/2][17:0] ram;

endmodule