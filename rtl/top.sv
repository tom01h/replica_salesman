module top
    import replica_pkg::*;
(
    input  logic                      clk,
    input  logic                      reset,
    
    input  logic [31:0]               S_AXI_AWADDR,
    input  logic                      S_AXI_AWVALID,
    output logic                      S_AXI_AWREADY,
    input  logic [63:0]               S_AXI_WDATA,
    input  logic [7:0]                S_AXI_WSTRB,
    input  logic                      S_AXI_WVALID,
    output logic                      S_AXI_WREADY,
    output logic [1:0]                S_AXI_BRESP,
    output logic                      S_AXI_BVALID,
    input  logic                      S_AXI_BREADY,

    input  logic [31:0]               S_AXI_ARADDR,
    input  logic                      S_AXI_ARVALID,
    output logic                      S_AXI_ARREADY,
    output logic [63:0]               S_AXI_RDATA,
    output logic [1:0]                S_AXI_RRESP,
    output logic                      S_AXI_RVALID,
    input  logic                      S_AXI_RREADY
);

logic [node_num-1:0]       random_init;
logic [node_num-1:0]       random_read;
logic [63:0]               random_seed_w;
logic [node_num-1:0][63:0] random_seed_r;

logic                      tp_dis_write;
logic [city_num_log*2-2:0] tp_dis_waddr;
distance_data_t            tp_dis_wdata;

logic                      ordering_write;
logic [7:0][7:0]           ordering_wdata;

logic                      ordering_read;
logic [7:0][7:0]           ordering_rdata;
logic                      ordering_ready;

logic                      distance_shift;
logic                      distance_shift_n;
total_data_t               distance_wdata;
total_data_t               distance_rdata;

logic                      run_write;
logic [23:0]               run_times;
logic                      running;

logic                      exchange_shift_d;
logic                      exchange_shift_n;

bus_if busif
(
    .S_AXI_ACLK       ( clk              ),
    .S_AXI_ARESETN    ( ~reset           ),

    .S_AXI_AWADDR     ( S_AXI_AWADDR     ),
    .S_AXI_AWVALID    ( S_AXI_AWVALID    ),
    .S_AXI_AWREADY    ( S_AXI_AWREADY    ),
    .S_AXI_WDATA      ( S_AXI_WDATA      ),
    .S_AXI_WSTRB      ( S_AXI_WSTRB      ),
    .S_AXI_WVALID     ( S_AXI_WVALID     ),
    .S_AXI_WREADY     ( S_AXI_WREADY     ),
    .S_AXI_BRESP      ( S_AXI_BRESP      ),
    .S_AXI_BVALID     ( S_AXI_BVALID     ),
    .S_AXI_BREADY     ( S_AXI_BREADY     ),

    .S_AXI_ARADDR     ( S_AXI_ARADDR     ),
    .S_AXI_ARVALID    ( S_AXI_ARVALID    ),
    .S_AXI_ARREADY    ( S_AXI_ARREADY    ),
    .S_AXI_RDATA      ( S_AXI_RDATA      ),
    .S_AXI_RRESP      ( S_AXI_RRESP      ),
    .S_AXI_RVALID     ( S_AXI_RVALID     ),
    .S_AXI_RREADY     ( S_AXI_RREADY     ),

    .random_init      ( random_init      ),
    .random_read      ( random_read      ),
    .random_seed_w    ( random_seed_w    ),
    .random_seed_r    ( random_seed_r    ),

    .tp_dis_write     ( tp_dis_write     ),
    .tp_dis_waddr     ( tp_dis_waddr     ),
    .tp_dis_wdata     ( tp_dis_wdata     ),

    .ordering_write   ( ordering_write   ),
    .ordering_wdata   ( ordering_wdata   ),

    .ordering_read    ( ordering_read    ),
    .ordering_rdata   ( ordering_rdata   ),
    .ordering_ready   ( ordering_ready   ),

    .distance_shift   ( distance_shift   ),
    .distance_shift_n ( distance_shift_n ),
    .distance_wdata   ( distance_wdata   ),
    .distance_rdata   ( distance_rdata   ),

    .run_write        ( run_write        ),
    .run_times        ( run_times        ),

    .running          ( running          )
);
   
logic             [node_num+1:0]  or_ordering_valid;
replica_data_t    [node_num+1:0]  or_ordering_data;
logic             [node_num+1:0]  tw_ordering_valid;
replica_data_t    [node_num+1:0]  tw_ordering_data;

logic                             ordering_out_valid;
replica_data_t                    ordering_out_data;
logic                             ordering_reg_valid;
replica_data_t                    ordering_reg_data;

total_data_t      [node_num+1:0]  or_dis_data;
total_data_t      [node_num+1:0]  tw_dis_data;

assign or_ordering_valid[0]  = (running) ? or_ordering_valid[node_num] : ordering_reg_valid;
assign or_ordering_data[0]   = (running) ? or_ordering_data[node_num ] : ordering_reg_data;
assign or_ordering_valid[node_num+1]  = or_ordering_valid[1];
assign or_ordering_data[node_num+1]   = or_ordering_data[1];
assign tw_ordering_valid[0]  = ordering_reg_valid;
assign tw_ordering_data[0]   = ordering_reg_data;

assign or_dis_data[0]          = (running) ? or_dis_data[node_num] : distance_wdata;
assign or_dis_data[node_num+1] = (running) ? or_dis_data[1]        : 'b0;
assign tw_dis_data[0] = distance_wdata;

logic [city_div_log - 1:0] ord_rd_num;
logic                      ord_rd_bank;
always_ff @(posedge clk) begin
    if(reset)                          begin ord_rd_bank <= 'b0;          ord_rd_num <= '0; end
    else if(ordering_read) begin
        if(ord_rd_num == city_div - 1) begin ord_rd_bank <= ~ord_rd_bank; ord_rd_num <= '0; end
        else                                                              ord_rd_num <= ord_rd_num +1;
    end
end
assign ordering_out_valid = (ord_rd_bank) ? tw_ordering_valid[node_num] : or_ordering_valid[node_num];
assign ordering_out_data  = (ord_rd_bank) ? tw_ordering_data[node_num]  : or_ordering_data[node_num];

assign distance_rdata = or_dis_data[node_num];

node_reg node_reg
(
    .clk                ( clk                ),
    .reset              ( reset              ),
    .ordering_num       ( city_div - 1       ),
    
    .ordering_read      ( ordering_read      ),
    .ordering_out_valid ( ordering_out_valid ),
    .ordering_out_data  ( ordering_out_data  ),
    .ordering_rdata     ( ordering_rdata     ),
    
    .ordering_write     ( ordering_write     ),
    .ordering_wdata     ( ordering_wdata     ),
    .ordering_reg_valid ( ordering_reg_valid ),
    .ordering_reg_data  ( ordering_reg_data  ),
    
    .ordering_ready     ( ordering_ready     ),
    
    .exchange_shift_d   ( exchange_shift_d   ),
    .exchange_shift_n   ( exchange_shift_n   )
);

distance_command_t    or_distance_com;
distance_command_t    tw_distance_com;

logic                 exp_init;
logic                 exp_run;
logic                 exp_fin;
logic [16:0]          exp_recip;

logic                 opt_run;
logic                 or_opt_en;
logic                 tw_opt_en;

wire change_base_id = random_init[node_num-1] || random_read[node_num-1] || exchange_shift_n || distance_shift_n;
logic [base_log-1:0]     or_rn_base_id;
logic [base_log-1:0]     tw_rn_base_id;
logic [base_log-1:0]     or_dd_base_id;
logic [base_log-1:0]     tw_dd_base_id;
logic [base_log-1:0]     or_rp_base_id;
logic [base_log-1:0]     tw_rp_base_id;
logic [base_log-1:0]     or_ex_base_id;
logic [base_log-1:0]     tw_ex_base_id;

node_control node_control
(
    .clk               ( clk               ),
    .reset             ( reset             ),
    .run_write         ( run_write         ),
    .run_times         ( run_times         ),
    .running           ( running           ),

    .change_base_id    ( change_base_id    ),
    .or_rn_base_id     ( or_rn_base_id     ),
    .tw_rn_base_id     ( tw_rn_base_id     ),
    .or_dd_base_id     ( or_dd_base_id     ),
    .tw_dd_base_id     ( tw_dd_base_id     ),
    .or_rp_base_id     ( or_rp_base_id     ),
    .tw_rp_base_id     ( tw_rp_base_id     ),
    .or_ex_base_id     ( or_ex_base_id     ),
    .tw_ex_base_id     ( tw_ex_base_id     ),

    .opt_run           ( opt_run           ),
    .or_opt_en         ( or_opt_en         ),
    .tw_opt_en         ( tw_opt_en         ),
    
    .or_distance_com   ( or_distance_com   ),
    .tw_distance_com   ( tw_distance_com   ),
    
    .exp_init          ( exp_init          ),
    .exp_run           ( exp_run           ),
    .exp_fin           ( exp_fin           ),
    .exp_recip         ( exp_recip         )
);

logic             [node_num+1:0]  or_exchange;

assign or_exchange[0]          = (running) ? or_exchange[node_num] : 'b0;
assign or_exchange[node_num+1] = (running) ? or_exchange[1]        : 'b0;

logic             [node_num+1:0]  tw_exchange;

assign tw_exchange[0] = 'b0;
assign tw_exchange[node_num+1] = 'b0;

for (genvar g = 0; g < node_num; g += 1) begin
    node #(.id(g)) node
    (
        .clk               ( clk                   ),
        .reset             ( reset                 ),
        
        .or_rn_base_id     ( or_rn_base_id         ),
        .tw_rn_base_id     ( tw_rn_base_id         ),
        .or_dd_base_id     ( (g!=(node_num-1) | ~running) ? or_dd_base_id : or_dd_base_id-1'b1 ), // TEMP or_dd_base_id_M
        .tw_dd_base_id     ( tw_dd_base_id         ),
        .or_rp_base_id     ( (g!=(node_num-1) | ~running) ? or_rp_base_id : or_rp_base_id-1'b1 ), // TEMP or_rp_base_id_M
        .tw_rp_base_id     ( tw_rp_base_id         ),
        .or_ex_base_id     ( (g!=(node_num-1) | ~running) ? or_ex_base_id : or_ex_base_id-1'b1 ), // TEMP or_ex_base_id_M
        .tw_ex_base_id     ( tw_ex_base_id         ),
        
        .random_init       ( random_init[g]        ), // set random seed
        .random_read       ( random_read[g]        ), // get random seed
        .random_seed_w     ( random_seed_w         ),
        .random_seed_r     ( random_seed_r[g]      ),
        .tp_dis_write      ( tp_dis_write          ), // set 2点間距離
        .tp_dis_waddr      ( tp_dis_waddr          ),
        .tp_dis_wdata      ( tp_dis_wdata          ),
        .distance_shift    ( distance_shift        ), // total distance read/write
        .exchange_shift_d  ( exchange_shift_d      ), // ordering read/write
        
        .opt_run           ( opt_run               ), // opt run
        .or_opt_en         ( or_opt_en             ), // opt en
        .tw_opt_en         ( tw_opt_en             ), // opt en

        .or_distance_com   ( or_distance_com        ), // delta distance
        .tw_distance_com   ( tw_distance_com        ), // delta distance

        .or_prev_dis_data  ( or_dis_data[g]         ),
        .or_folw_dis_data  ( or_dis_data[g+2]       ),
        .or_out_dis_data   ( or_dis_data[g+1]       ),
        
        .or_prev_exchange  ( or_exchange[g]         ),
        .or_folw_exchange  ( or_exchange[g+2]       ),
        .or_out_exchange   ( or_exchange[g+1]       ),

        .or_prev_ord_valid ( or_ordering_valid[g]   ),
        .or_prev_ord_data  ( or_ordering_data[g]    ),
        .or_folw_ord_valid ( or_ordering_valid[g+2] ),
        .or_folw_ord_data  ( or_ordering_data[g+2]  ),
        .or_out_ord_valid  ( or_ordering_valid[g+1] ),
        .or_out_ord_data   ( or_ordering_data[g+1]  ),

        .tw_prev_dis_data  ( tw_dis_data[g]         ),
        .tw_folw_dis_data  ( tw_dis_data[g+2]       ),
        .tw_out_dis_data   ( tw_dis_data[g+1]       ),
        
        .tw_prev_exchange  ( tw_exchange[g]         ),
        .tw_folw_exchange  ( tw_exchange[g+2]       ),
        .tw_out_exchange   ( tw_exchange[g+1]       ),

        .tw_prev_ord_valid ( tw_ordering_valid[g]   ),
        .tw_prev_ord_data  ( tw_ordering_data[g]    ),
        .tw_folw_ord_valid ( tw_ordering_valid[g+2] ),
        .tw_folw_ord_data  ( tw_ordering_data[g+2]  ),
        .tw_out_ord_valid  ( tw_ordering_valid[g+1] ),
        .tw_out_ord_data   ( tw_ordering_data[g+1]  ),

        .exp_init          ( exp_init               ),
        .exp_run           ( exp_run                ),
        .exp_fin           ( exp_fin                ),
        .exp_recip         ( exp_recip              )
    );
end

endmodule