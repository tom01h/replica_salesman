module minimun
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    min_ord_read,
    output logic                    ordering_min_valid,
    output replica_data_t           ordering_min_data,
    input  logic                    read_minimum_distance,
    input  logic                    update_minimum_distance,
    input  logic                    opt_run,
    input  total_data_t             minimum_distance,
    input  exchange_command_t       minimum_ex_com,
    input  logic                    prev_ord_valid,
    input  replica_data_t           prev_ord_data,
    input  logic                    self_ord_valid,
    input  replica_data_t           self_ord_data

);

logic                       run_update;
logic [city_div_log-1 : 0]  wcount;
logic                       write_valid;
replica_data_t              write_data;
total_data_t                in_distance;
total_data_t                min_distance;
logic                       update_d;

always_ff @(posedge clk) begin
    update_d <= update_minimum_distance;
    if(reset) begin
        run_update   <= 1'b0;
        wcount       <= 'b0;
        min_distance <= -1;
    end else if(update_minimum_distance) begin
        run_update   <= 1'b1;
        wcount       <= 'b0;
        in_distance  <= minimum_distance;
    end else if(update_d) begin
        if(min_distance > in_distance)begin
            min_distance <= in_distance;
        end else begin
            run_update   <= 1'b0;
        end
    end else if(opt_run) begin
        run_update   <= 1'b0;
    end else if(write_valid) begin
        wcount       <= wcount + 1'b1;
    end    
end

assign write_valid = ((minimum_ex_com == PREV) ? prev_ord_valid :
                      (minimum_ex_com == SELF) ? self_ord_valid : '0)
                     && run_update;
assign write_data  = (minimum_ex_com == PREV) ? prev_ord_data : self_ord_data;
                     
logic [city_div_log-1 : 0]  rcount;

always_ff @(posedge clk) begin
    if(reset)             rcount <= 'b0;
    else if(opt_run)      rcount <= 'b0;
    else if(min_ord_read) rcount <= rcount + 1'b1;

    ordering_min_valid <= min_ord_read;
end
                     
logic [replica_data_bit-1:0] ram [0:2**(city_div_log) -1];
always_ff @(posedge clk) begin
    if (write_valid) begin
        ram[wcount] <= write_data;
    end
    ordering_min_data <= ram[rcount];
end
endmodule