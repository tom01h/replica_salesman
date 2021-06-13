module bus_if
    import replica_pkg::*;
(
    input  logic                      S_AXI_ACLK,
    input  logic                      S_AXI_ARESETN,

    ////////////////////////////////////////////////////////////////////////////
    // AXI Lite Slave Interface
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

    output logic [node_num-1:0]       random_init,
    output logic [63:0]               random_seed,

    output logic                      tp_dis_write,
    output logic [city_num_log*2-1:0] tp_dis_waddr,
    output distance_data_t            tp_dis_wdata,

    output logic                      ordering_write,
    output logic [7:0][7:0]           ordering_wdata,

    output logic                      ordering_read,
    input  logic [7:0][7:0]           ordering_rdata,
    input  logic                      ordering_ready,

    output logic                      distance_shift,
    output logic                      distance_shift_n,
    output total_data_t               distance_wdata,
    input  total_data_t               distance_rdata,

    output logic                      run_write,
    output logic [23:0]               run_times,

    input  logic                      running    
);

    logic [3:0]         axist;
    logic [31:2]        wb_adr_i;
    logic [31:2]        rd_adr_i;
    logic [63:0]        wb_dat_i;

    assign S_AXI_BRESP = 2'b00;
    assign S_AXI_RRESP = 2'b00;
    assign S_AXI_AWREADY = (axist == 4'b0000)|(axist == 4'b0010);
    assign S_AXI_WREADY  = (axist == 4'b0000)|(axist == 4'b0001);
    assign S_AXI_ARREADY = (axist == 4'b0000);
    assign S_AXI_BVALID  = (axist == 4'b0011);
    assign S_AXI_RVALID  = (axist == 4'b1000) & ordering_ready;
    
    always_comb begin
        for(int i = 0; i < node_num; i++) begin
            random_init[i] = S_AXI_BVALID && (wb_adr_i[3 +: node_log] == i) && (wb_adr_i[19:12] == 8'h01);
        end
        random_seed = wb_dat_i;

        tp_dis_write = S_AXI_BVALID && (wb_adr_i[19:16] == 4'h1);
        tp_dis_waddr = wb_adr_i[$bits(tp_dis_waddr)-1+3:3];
        tp_dis_wdata = wb_dat_i[$bits(tp_dis_wdata)-1  :0];
        
        ordering_write = S_AXI_BVALID && ({wb_adr_i[19:15],3'b000} == 8'h08);
        for(int j = 0; j < 8; j++)
            ordering_wdata[j] = wb_dat_i[j*8 +:8];

        ordering_read    = S_AXI_ARVALID && S_AXI_ARREADY && ({S_AXI_ARADDR[19:15],3'b000} == 8'h08);

        distance_shift   = S_AXI_BVALID && (wb_adr_i[19:12] == 8'h02) ||
                           S_AXI_ARVALID && S_AXI_ARREADY && (S_AXI_ARADDR[19:12] == 8'h02);
        distance_shift_n = S_AXI_BVALID && (wb_adr_i[19:12] == 8'h02) && (wb_adr_i[3 +:node_log] == node_num-1) ||
                           S_AXI_ARVALID && S_AXI_ARREADY && (S_AXI_ARADDR[19:12] == 8'h02) && (S_AXI_ARADDR[3 +:node_log] == node_num-1);
        distance_wdata   = wb_dat_i[$bits(distance_wdata)-1:0];

        run_write = (S_AXI_BVALID && (wb_adr_i[19:2] == 'h0));
        run_times = wb_dat_i[$bits(run_times)-1  :0];
    end

    total_data_t               distance_rdata_d;
    always_ff @(posedge S_AXI_ACLK)
        if(distance_shift) distance_rdata_d <= distance_rdata;

    always_comb begin
        if({rd_adr_i[19:2],2'b00} == 'h0)
            S_AXI_RDATA = running;
        if({rd_adr_i[19:15],3'b000} == 8'h08)
            for(int j = 0; j < 8; j++)
                S_AXI_RDATA[j*8 +:8] = ordering_rdata[j];
        if(rd_adr_i[19:12] == 8'h02)
            S_AXI_RDATA = distance_rdata_d;
    end
        
    always_ff @(posedge S_AXI_ACLK)begin
        if(~S_AXI_ARESETN)begin
            axist<=4'b0000;

            wb_adr_i<=0;
            wb_dat_i<=0;
        end else if(axist==4'b000)begin
            if(S_AXI_AWVALID & S_AXI_WVALID)begin
                axist<=4'b0011;
                wb_adr_i[31:2]<=S_AXI_AWADDR[31:2];
                wb_dat_i<=S_AXI_WDATA;
            end else if(S_AXI_AWVALID)begin
                axist<=4'b0001;
                wb_adr_i[31:2]<=S_AXI_AWADDR[31:2];
            end else if(S_AXI_WVALID)begin
                axist<=4'b0010;
                wb_dat_i<=S_AXI_WDATA;
            end else if(S_AXI_ARVALID)begin
                axist<=4'b0100;
                rd_adr_i[31:2]<=S_AXI_ARADDR[31:2];
            end
        end else if(axist==4'b0001)begin
            if(S_AXI_WVALID)begin
                axist<=4'b0011;
                wb_dat_i<=S_AXI_WDATA;
            end
        end else if(axist==4'b0010)begin
            if(S_AXI_AWVALID)begin
                axist<=4'b0011;
                wb_adr_i[31:2]<=S_AXI_AWADDR[31:2];
            end
        end else if(axist==4'b0011)begin
            if(S_AXI_BREADY)
                axist<=4'b0000;
        end else if(axist==4'b0100)begin
                axist<=4'b1000;
        end else if(axist==4'b1000)begin
            if(S_AXI_RREADY & ordering_ready)
                axist<=4'b0000;
        end
    end

endmodule
