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
    input  logic                      S_AXI_RREADY,

    input  logic                      opt_run,
    input  opt_command_t              opt_com,
    
    input  logic                      distance_shift,
    output total_data_t               distance_rdata,

    input  logic                      ordering_read,
    output logic [7:0][7:0]           ordering_rdata,
    output logic                      ordering_ready
);

logic [replica_num-1:0]    random_init;
logic [63:0]               random_seed;

logic                      tp_dis_write;
logic [city_num_log*2-1:0] tp_dis_waddr;
distance_data_t            tp_dis_wdata;

logic                      ordering_write;
logic [7:0][7:0]           ordering_wdata;

logic                      distance_shift_w;
total_data_t               distance_wdata;

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

    .distance_shift  ( distance_shift_w ),
    .distance_wdata  ( distance_wdata )
);
   
logic                                exchange_shift;
logic                                exchange_shift_d;

logic             [replica_num+1:0]  ordering_valid;
replica_data_t    [replica_num+1:0]  ordering_data;
logic                                ordering_out_valid;
replica_data_t                       ordering_out_data;
logic                                ordering_reg_valid;
replica_data_t                       ordering_reg_data;

assign ordering_valid[0]  = ordering_reg_valid;
assign ordering_data[0]   = ordering_reg_data;
assign ordering_out_valid = ordering_valid[replica_num];
assign ordering_out_data  = ordering_data[replica_num];

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

logic                 random_run;
distance_command_t    distance_com;
logic                 metropolis_run;
logic                 replica_run;
logic                 exchange_run;
logic                 exchange_bank;
logic                 exp_init;
logic                 exp_run;
logic [16:0]          exp_recip;
node_control node_control
(
    .clk            ( clk            ),
    .reset          ( reset          ),
    .run            ( opt_run        ),
    .opt_command    ( opt_com        ),
    .random_run     ( random_run     ),
    .distance_com   ( distance_com   ),
    .metropolis_run ( metropolis_run ),
    .replica_run    ( replica_run    ),
    .exchange_run   ( exchange_run   ),
    .exchange_bank  ( exchange_bank  ),
    .exchange_shift ( exchange_shift ),
    .exp_init       ( exp_init       ),
    .exp_run        ( exp_run        ),
    .exp_recip      ( exp_recip      )
);

total_data_t      [replica_num+1:0]  dis_data;
logic             [replica_num+1:0]  t_exchange;

assign dis_data[0] = distance_wdata;
assign distance_rdata = dis_data[replica_num];
assign t_exchange[0] = 'b0;
assign t_exchange[replica_num+1] = 'b0;

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
        .distance_shift   ( distance_shift | distance_shift_w      ), // total distance read/write
        .exchange_shift_d ( exchange_shift_d    ), // ordering read/write
        
        .opt_command      ( opt_com             ), // opt mode
        
        .random_run       ( random_run          ), // random
        .distance_com     ( distance_com        ), // delta distance
        .metropolis_run   ( metropolis_run      ), // metropolis test
        .replica_run      ( replica_run         ), // replica exchange test
        .exchange_run     ( exchange_run        ), // chenge ordering & replica exchange

        .exchange_bank    ( exchange_bank       ),

        .prev_dis_data    ( dis_data[g]         ),
        .folw_dis_data    ( dis_data[g+2]       ),
        .out_dis_data     ( dis_data[g+1]       ),
        
        .prev_exchange    ( t_exchange[g]       ),
        .folw_exchange    ( t_exchange[g+2]     ),
        .out_exchange     ( t_exchange[g+1]     ),

        .prev_ord_valid   ( ordering_valid[g]   ),
        .prev_ord_data    ( ordering_data[g]    ),
        .folw_ord_valid   ( ordering_valid[g+2] ),
        .folw_ord_data    ( ordering_data[g+2]  ),
        .out_ord_valid    ( ordering_valid[g+1] ),
        .out_ord_data     ( ordering_data[g+1]  ),

        .exp_init         ( exp_init            ),
        .exp_run          ( exp_run             ),
        .exp_recip        ( exp_recip           )
);
end

endmodule