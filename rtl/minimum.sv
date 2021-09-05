module minimun
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,

    input  logic                    min_ord_read,
    output logic                    ordering_min_valid,
    output replica_data_t           ordering_min_data,
    
    input  logic                    siter_write,
    input  logic [19:0]             siter,
    input  logic                    min_distance_read,
    output logic                    distance_min_valid,
    output total_data_t             distance_min_data,
    
    input  logic                    update_minimum_distance,
    input  logic                    opt_run,
    input  total_data_t             minimum_distance,
    input  exchange_command_t       minimum_ex_com,
    input  logic                    prev_ord_valid,
    input  replica_data_t           prev_ord_data,
    input  logic                    self_ord_valid,
    input  replica_data_t           self_ord_data

);

logic                      run_update;
logic [city_div_log-1 : 0] wcount;
logic                      write_valid;
replica_data_t             write_data;
total_data_t               in_distance;
total_data_t               min_distance;
logic                      update_d;
logic                      update_w;

always_ff @(posedge clk) begin
    update_d <= update_minimum_distance;
    update_w <= update_d;
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
                     
logic [replica_data_bit-1:0] ord_ram [0:2**(city_div_log) -1];
always_ff @(posedge clk) begin
    if (write_valid) begin
        ord_ram[wcount] <= write_data;
    end
    ordering_min_data <= ord_ram[rcount];
end

logic [19:0]               siter_i;
logic [19:0]               siter_cout;
logic                      siter_last;
logic [siter_log-1 : 0]    dist_save_ptr;
logic [siter_log-1 : 0]    dist_read_ptr;

assign siter_last = (siter_cout + 1) == siter_i;
always_ff @(posedge clk)
    if(siter_write) begin
        siter_i      <= siter/2;
        siter_cout   <= 'b0;
        dist_save_ptr <= 'b0;
    end else if(update_w) begin
        if(siter_last)begin
            siter_cout   <= 'b0;
            dist_save_ptr <= dist_save_ptr + 1'b1;
        end else begin
            siter_cout   <= siter_cout + 1'b1;
        end    
    end    

logic dist_write;
assign dist_write = update_w && siter_last;

always_ff @(posedge clk) begin
    distance_min_valid <= min_distance_read;
    if(siter_write)            dist_read_ptr <= 'b0;
    else if(min_distance_read) dist_read_ptr <= dist_read_ptr + 1'b1;
end

logic [$bits(total_data_t)-1:0] dist_ram [0:2**(siter_log) -1];
always_ff @(posedge clk) begin
    if (dist_write) begin
        dist_ram[dist_save_ptr] <= min_distance;
    end
    distance_min_data <= dist_ram[dist_read_ptr];
end

endmodule