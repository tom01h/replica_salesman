module node_reg
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    
    input  logic [city_div_log-1:0] ordering_num,
    
    input  logic                    ordering_read,
    input  logic                    ordering_out_valid,
    input  replica_data_t           ordering_out_data,
    output logic [7:0][7:0]         ordering_rdata,
    
    input  logic                    ordering_write,
    input  logic [7:0][7:0]         ordering_wdata,
    output logic                    ordering_reg_valid,
    output replica_data_t           ordering_reg_data,

    output logic                    ordering_ready,

    output logic                    exchange_shift_d,
    output logic                    exchange_shift_n
);

replica_data_t [city_div-1:0]     ordering_data;
logic          [city_div_log:0]   ordering_wadder;
logic          [city_div_log:0]   ordering_radder;
logic                             ordering_wready;
logic                             ordering_rready;
logic                             ordering_read_en;
logic          [city_div_log-1:0] ordering_cnt;
logic          [node_log-1:0]     ordering_node;

assign ordering_ready   = ordering_wready & ordering_rready;
assign ordering_read_en = ordering_wadder != ordering_radder;

logic                    exchange_shift;
assign exchange_shift   = (ordering_write || ordering_read) && ordering_ready && (ordering_cnt == 'b0);
assign exchange_shift_n = (ordering_write || ordering_read) && ordering_ready && (ordering_cnt == ordering_num) && (ordering_node == node_num-1);

always_ff @(posedge clk) begin
    if(reset)                   ordering_rready <= 'b1;
    else if(exchange_shift)     ordering_rready <= 'b0;
    else if(ordering_read_en)   ordering_rready <= 'b1;
    
    if(reset)                   ordering_wadder <= 'b0;
    else if(exchange_shift)     ordering_wadder <= 'b0;
    else if(ordering_out_valid && ordering_wadder <= city_div)
                                ordering_wadder <= ordering_wadder + 1;
    if(ordering_out_valid)      ordering_data[ordering_wadder] <= ordering_out_data;
end

always_ff @(posedge clk)
    for(int i=0; i<8; i++) ordering_rdata[i] = {1'b0, ordering_data[ordering_radder][7-i]};

always_ff @(posedge clk) begin
    exchange_shift_d <= exchange_shift;    
    ordering_wready  <= 1'b1;
    if(reset) begin
        ordering_cnt   <= 'b0;
        ordering_node  <= 'b0;
        ordering_radder <= '1;
    end else if(ordering_write) begin
        ordering_radder <= '1;
        if(ordering_cnt == ordering_num) begin                     ordering_cnt <= 'b0;
            if(ordering_node == node_num-1) ordering_node <= '0;
            else                            ordering_node <= ordering_node +1;
        end else if(ordering_ready) begin
            if(ordering_cnt == 'b0) begin ordering_wready <= 1'b0; ordering_cnt <= ordering_cnt + 1; end
            else                                                   ordering_cnt <= ordering_cnt + 1;
        end
    end else if(ordering_read) begin
        if(ordering_cnt == ordering_num) begin                     ordering_cnt <= 'b0;
            if(ordering_node == node_num-1) ordering_node <= '0;
            else                            ordering_node <= ordering_node +1;
        end else if(ordering_read_en)                              ordering_cnt <= ordering_cnt + 1;
        if(ordering_read_en)              ordering_radder <= ordering_cnt;
    end
end

logic                     in_valid_d1,   in_valid_d2,   in_valid_d3;
replica_data_t            in_data_d1,    in_data_d2,    in_data_d3;

assign ordering_reg_valid = in_valid_d3;
assign ordering_reg_data  = in_data_d3;

always_ff @(posedge clk)begin
    if(ordering_wready)begin
        in_valid_d1 <= ordering_write;
        for(int i=0; i<8; i++) in_data_d1[i][6:0] <= ordering_wdata[i][6:0];
        in_valid_d2 <= in_valid_d1;
        in_data_d2 <= in_data_d1;
    end
    in_valid_d3 <= in_valid_d2;
    in_data_d3 <= in_data_d2;
end

endmodule