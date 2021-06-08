module top
    import replica_pkg::*;
#(
    parameter replica_num = 32
)
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

logic [replica_num-1:0]    random_init;
logic [63:0]               random_seed;

logic                      tp_dis_write;
logic [city_num_log*2-1:0] tp_dis_waddr;
distance_data_t            tp_dis_wdata;

logic                      ordering_write;
logic [7:0][7:0]           ordering_wdata;

logic                      ordering_read;
logic [7:0][7:0]           ordering_rdata;
logic                      ordering_ready;

logic                      distance_shift;
total_data_t               distance_wdata;
total_data_t               distance_rdata;

logic                      run_write;
logic [23:0]               run_times;

logic                      running;

bus_if #(.replica_num(replica_num)) busif
(
    .S_AXI_ACLK      ( clk            ),
    .S_AXI_ARESETN   ( ~reset         ),

    .S_AXI_AWADDR    ( S_AXI_AWADDR   ),
    .S_AXI_AWVALID   ( S_AXI_AWVALID  ),
    .S_AXI_AWREADY   ( S_AXI_AWREADY  ),
    .S_AXI_WDATA     ( S_AXI_WDATA    ),
    .S_AXI_WSTRB     ( S_AXI_WSTRB    ),
    .S_AXI_WVALID    ( S_AXI_WVALID   ),
    .S_AXI_WREADY    ( S_AXI_WREADY   ),
    .S_AXI_BRESP     ( S_AXI_BRESP    ),
    .S_AXI_BVALID    ( S_AXI_BVALID   ),
    .S_AXI_BREADY    ( S_AXI_BREADY   ),

    .S_AXI_ARADDR    ( S_AXI_ARADDR   ),
    .S_AXI_ARVALID   ( S_AXI_ARVALID  ),
    .S_AXI_ARREADY   ( S_AXI_ARREADY  ),
    .S_AXI_RDATA     ( S_AXI_RDATA    ),
    .S_AXI_RRESP     ( S_AXI_RRESP    ),
    .S_AXI_RVALID    ( S_AXI_RVALID   ),
    .S_AXI_RREADY    ( S_AXI_RREADY   ),

    .random_init     ( random_init    ),
    .random_seed     ( random_seed    ),

    .tp_dis_write    ( tp_dis_write   ),
    .tp_dis_waddr    ( tp_dis_waddr   ),
    .tp_dis_wdata    ( tp_dis_wdata   ),

    .ordering_write  ( ordering_write ),
    .ordering_wdata  ( ordering_wdata ),

    .ordering_read   ( ordering_read  ),
    .ordering_rdata  ( ordering_rdata ),
    .ordering_ready  ( ordering_ready ),

    .distance_shift  ( distance_shift ),
    .distance_wdata  ( distance_wdata ),
    .distance_rdata  ( distance_rdata ),

    .run_write       ( run_write      ),
    .run_times       ( run_times      ),

    .running         ( running        )
);
   
logic                                exchange_shift;
logic                                exchange_shift_d;

logic             [replica_num+1:0]  or_ordering_valid;
replica_data_t    [replica_num+1:0]  or_ordering_data;
logic             [replica_num+1:0]  tw_ordering_valid;
replica_data_t    [replica_num+1:0]  tw_ordering_data;

logic                                ordering_out_valid;
replica_data_t                       ordering_out_data;
logic                                ordering_reg_valid;
replica_data_t                       ordering_reg_data;

total_data_t      [replica_num+1:0]  or_dis_data;
total_data_t      [replica_num+1:0]  tw_dis_data;

assign or_ordering_valid[0]  = ordering_reg_valid;
assign or_ordering_data[0]   = ordering_reg_data;
assign tw_ordering_valid[0]  = ordering_reg_valid;
assign tw_ordering_data[0]   = ordering_reg_data;

assign or_dis_data[0] = distance_wdata;
assign tw_dis_data[0] = distance_wdata;

logic [2:0] ord_rd_num;
always_ff @(posedge clk) begin
    if(reset)              ord_rd_num <= '0;
    else if(ordering_read) ord_rd_num <= ord_rd_num + 1;
end
assign ordering_out_valid = (ord_rd_num[2]) ? tw_ordering_valid[replica_num] : or_ordering_valid[replica_num];
assign ordering_out_data  = (ord_rd_num[2]) ? tw_ordering_data[replica_num]  : or_ordering_data[replica_num];

logic dis_rd_num;
always_ff @(posedge clk) begin
    if(reset)               dis_rd_num <= 'b0;
    else if(distance_shift) dis_rd_num <= ~dis_rd_num;
end
assign distance_rdata = (dis_rd_num) ? or_dis_data[replica_num] : tw_dis_data[replica_num];

node_reg node_reg
(
    .clk                ( clk                ),
    .reset              ( reset              ),
    .ordering_num       ( 2'd3               ),
    
    .ordering_read      ( ordering_read      ),
    .ordering_out_valid ( ordering_out_valid ),
    .ordering_out_data  ( ordering_out_data  ),
    .ordering_rdata     ( ordering_rdata     ),
    
    .ordering_write     ( ordering_write     ),
    .ordering_wdata     ( ordering_wdata     ),
    .ordering_reg_valid ( ordering_reg_valid ),
    .ordering_reg_data  ( ordering_reg_data  ),
    
    .ordering_ready     ( ordering_ready     ),
    
    .exchange_shift     ( exchange_shift     ),
    .exchange_shift_d   ( exchange_shift_d   )
);

distance_command_t    or_distance_com;
distance_command_t    tw_distance_com;

logic                 exp_init;
logic                 exp_run;
logic                 exp_fin;
logic [16:0]          exp_recip;

logic                 opt_run;
opt_command_t         opt_com;

node_control node_control
(
    .clk            ( clk            ),
    .reset          ( reset          ),
    .run_write      ( run_write      ),
    .run_times      ( run_times      ),
    .running        ( running        ),

    .opt_run        ( opt_run        ),
    .opt_com        ( opt_com        ),
    
    .or_distance_com   ( or_distance_com   ),
    .tw_distance_com   ( tw_distance_com   ),
    
    .exchange_shift ( exchange_shift ),
    .exp_init       ( exp_init       ),
    .exp_run        ( exp_run        ),
    .exp_fin        ( exp_fin        ),
    .exp_recip      ( exp_recip      )
);

logic             [replica_num+1:0]  or_exchange;

assign or_exchange[0] = 'b0;
assign or_exchange[replica_num+1] = 'b0;

logic             [replica_num+1:0]  tw_exchange;

assign tw_exchange[0] = 'b0;
assign tw_exchange[replica_num+1] = 'b0;

for (genvar g = 0; g < replica_num; g += 1) begin
    node #(.id(g), .replica_num(replica_num)) node
    (
        .clk              ( clk                 ),
        .reset            ( reset               ),
        
        .random_init      ( random_init[g]      ), // set random seed
        .random_seed      ( random_seed         ),
        .tp_dis_write     ( tp_dis_write        ), // set 2点間距離
        .tp_dis_waddr     ( tp_dis_waddr        ),
        .tp_dis_wdata     ( tp_dis_wdata        ),
        .distance_shift   ( distance_shift      ), // total distance read/write
        .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
        
        .opt_run          ( opt_run             ), // opt run
        .opt_com          ( opt_com             ), // opt mode

        .or_distance_com     ( or_distance_com        ), // delta distance
        .tw_distance_com     ( tw_distance_com        ), // delta distance

        .or_prev_dis_data    ( or_dis_data[g]         ),
        .or_folw_dis_data    ( or_dis_data[g+2]       ),
        .or_out_dis_data     ( or_dis_data[g+1]       ),
        
        .or_prev_exchange    ( or_exchange[g]       ),
        .or_folw_exchange    ( or_exchange[g+2]     ),
        .or_out_exchange     ( or_exchange[g+1]     ),

        .or_prev_ord_valid   ( or_ordering_valid[g]   ),
        .or_prev_ord_data    ( or_ordering_data[g]    ),
        .or_folw_ord_valid   ( or_ordering_valid[g+2] ),
        .or_folw_ord_data    ( or_ordering_data[g+2]  ),
        .or_out_ord_valid    ( or_ordering_valid[g+1] ),
        .or_out_ord_data     ( or_ordering_data[g+1]  ),

        .tw_prev_dis_data    ( tw_dis_data[g]         ),
        .tw_folw_dis_data    ( tw_dis_data[g+2]       ),
        .tw_out_dis_data     ( tw_dis_data[g+1]       ),
        
        .tw_prev_exchange    ( tw_exchange[g]       ),
        .tw_folw_exchange    ( tw_exchange[g+2]     ),
        .tw_out_exchange     ( tw_exchange[g+1]     ),

        .tw_prev_ord_valid   ( tw_ordering_valid[g]   ),
        .tw_prev_ord_data    ( tw_ordering_data[g]    ),
        .tw_folw_ord_valid   ( tw_ordering_valid[g+2] ),
        .tw_folw_ord_data    ( tw_ordering_data[g+2]  ),
        .tw_out_ord_valid    ( tw_ordering_valid[g+1] ),
        .tw_out_ord_data     ( tw_ordering_data[g+1]  ),

        .exp_init         ( exp_init            ),
        .exp_run          ( exp_run             ),
        .exp_fin          ( exp_fin             ),
        .exp_recip        ( exp_recip           )
    );
end

endmodule