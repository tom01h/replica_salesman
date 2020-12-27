module top
    import replica_pkg::*;
#(
    parameter replica_num = 32
)
(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      set_random,
    input  logic [63:0]               random_seed,
    input  logic                      random_run,
    input  logic                      run_command,
    input  exchange_command_t         c_exchange,
    input  logic                      shift_distance,
    input  opt_command_t              opt_com,
    input  logic                      exchange_valid,
    input  logic                      distance_write,
    input  logic [city_num_log*2-1:0] distance_w_addr,
    input  distance_data_t            distance_w_data,
    input  total_data_t               total_in_data,
    output total_data_t               total_out_data,
    input  logic                      ordering_in_valid,
    input  logic [7:0][7:0]           ordering_in_data,
    output logic                      ordering_out_valid,
    output logic [7:0][7:0]           ordering_out_data

);

logic                     rbank;
exchange_command_t        c_exchange_d1;
logic                     in_valid_d1,   in_valid_d2,   in_valid_d3;
replica_data_t            in_data_d1,    in_data_d2,    in_data_d3;

logic [replica_num-1:0]   random_init;

always_ff @(posedge clk)begin
    if(reset) random_init <= 'b0;
    else      random_init <= {random_init,set_random};
end
    
always_ff @(posedge clk)begin
    if(reset)begin
        rbank <= '0;
        c_exchange_d1 <= NOP;
    end else begin
        if(run_command)begin
            rbank <= ~rbank;
            c_exchange_d1 <= c_exchange;
        end else begin
            c_exchange_d1 <= NOP;
        end    
        in_valid_d1 <= ordering_in_valid;
        for(int i=0; i<8; i++) in_data_d1[i][6:0] <= ordering_in_data[7-i][6:0];
        in_valid_d2 <= in_valid_d1;
        in_data_d2 <= in_data_d1;
        in_valid_d3 <= in_valid_d2;
        in_data_d3 <= in_data_d2;
    end
end

opt_command_t             opt_command;
integer count;
integer opt_count;
logic opt_run;
always_ff @(posedge clk)begin
    if(reset)begin
        opt_command            <= THR;
    end else if(run_command)begin
        count                  <= 0;
        opt_count              <= 0;
        opt_run                <= 1;
    end else if(opt_run)begin
        count                  <= count + 1;
        if(count == 5)begin
            opt_run            <= '0;
            opt_command        <= THR;
        end
    end else if(random_run)begin
        opt_command            <= opt_com;
    end
end

logic             [replica_num+1:0]  ordering_valid;
replica_data_t    [replica_num+1:0]  ordering_data;
total_data_t      [replica_num+1:0]  dis_data;
logic             [replica_num+1:0]  t_exchange;

assign ordering_valid[0] = in_valid_d3;
assign ordering_data[0]  = in_data_d3;
assign dis_data[0] = total_in_data;
assign total_out_data = dis_data[replica_num];
assign t_exchange[0] = 'b0;
assign t_exchange[replica_num+1] = 'b0;

always_comb
    for(int i=0; i<8; i++) ordering_out_data[i][6:0] = ordering_data[replica_num][7-i][6:0];

logic                 random_run_w;
distance_command_t    distance_com;
logic                 metropolis_run;
logic                 replica_run;
logic                 exchange_run;

node_control node_control
(
    .clk            ( clk            ),
    .reset          ( reset          ),
    .run            ( random_run     ),
    .opt_command    ( opt_command    ),
    .random_run     ( random_run_w   ),
    .distance_com   ( distance_com   ),
    .metropolis_run ( metropolis_run ),
    .replica_run    ( replica_run    ),
    .exchange_run   ( exchange_run   )
);

for (genvar g = 0; g < replica_num; g += 1) begin
    node #(.id(g), .replica_num(replica_num)) node
    (
        .clk             ( clk                 ),
        .reset           ( reset               ),
        .random_init     ( random_init[g]      ),
        .random_seed     ( random_seed         ),
        .random_run      ( random_run_w        ),
        .c_exchange      ( c_exchange_d1       ),
        .metropolis_run  ( metropolis_run      ),
        .replica_run     ( replica_run         ),
        .exchange_run    ( exchange_run        ),
        .shift_distance  ( shift_distance      ),
        .distance_com    ( distance_com        ),
        .opt_command     ( opt_command         ),
        .exchange_valid  ( exchange_valid      ),
        .rbank           ( rbank               ),
        .distance_write  ( distance_write      ),
        .distance_w_addr ( distance_w_addr     ),
        .distance_w_data ( distance_w_data     ),

        .prev_dis_data   ( dis_data[g]         ),
        .folw_dis_data   ( dis_data[g+2]       ),
        .out_dis_data    ( dis_data[g+1]       ),
        
        .prev_exchange   ( t_exchange[g]       ),
        .folw_exchange   ( t_exchange[g+2]     ),
        .out_exchange    ( t_exchange[g+1]     ),

        .prev_ord_valid  ( ordering_valid[g]   ),
        .prev_ord_data   ( ordering_data[g]    ),
        .folw_ord_valid  ( ordering_valid[g+2] ),
        .folw_ord_data   ( ordering_data[g+2]  ),
        .out_ord_valid   ( ordering_valid[g+1] ),
        .out_ord_data    ( ordering_data[g+1]  )
    );
end

endmodule