module node_reg
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic [city_div_log-1:0] ordering_num,
    input  logic                    ordering_read,
    input  logic                    ordering_out_valid,
    input  logic                    ordering_write,
    input  logic [7:0][7:0]         ordering_wdata,
    output logic                    ordering_reg_valid,
    output replica_data_t           ordering_reg_data,
    output logic                    ordering_ready,
    output logic                    exchange_shift,
    output logic                    exchange_shift_d
);

logic [city_div_log-1:0] ordering_cnt;
logic                    ordering_rready;

assign ordering_ready = ordering_rready || ordering_out_valid && ordering_read;
assign exchange_shift = (ordering_write || ordering_read) && ordering_ready && (ordering_cnt == 'b0);

always_ff @(posedge clk) begin
    exchange_shift_d <= exchange_shift;    
    if(reset) begin
        ordering_cnt   <= 'b0;
        ordering_rready <= 1'b1;
    end else if(ordering_write || ordering_read) begin
        if(ordering_cnt == ordering_num)               ordering_cnt <= 'b0;
        else if(ordering_cnt == 'b0 && ordering_ready) begin ordering_rready <= 1'b0; ordering_cnt <= ordering_cnt + 1; end
        else if(ordering_ready)                        ordering_cnt <= ordering_cnt + 1;
        else if(ordering_write)                        ordering_rready <= 1'b1;
    end
end

logic                     in_valid_d1,   in_valid_d2,   in_valid_d3;
replica_data_t            in_data_d1,    in_data_d2,    in_data_d3;

assign ordering_reg_valid = in_valid_d3;
assign ordering_reg_data  = in_data_d3;

always_ff @(posedge clk)begin
    in_valid_d1 <= ordering_write & (~ordering_ready || ordering_cnt != 'b0);
    for(int i=0; i<8; i++) in_data_d1[i][6:0] <= ordering_wdata[7-i][6:0];
    in_valid_d2 <= in_valid_d1;
    in_data_d2 <= in_data_d1;
    in_valid_d3 <= in_valid_d2;
    in_data_d3 <= in_data_d2;
end

endmodule