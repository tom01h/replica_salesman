module replica_ram
    import replica_pkg::*;
(
    input  logic           clk,
    input  logic           reset,
    input  replica_command command,
    input  replica_data    prev_data,
    input  replica_data    folw_data,
    output replica_data    out_data
);

replica_data [city_num-1:0]  ram;
logic        [city_num-1:0]  count;
logic        [city_num-1:0]  count_d1;
logic        [city_num-1:0]  count_d2;
logic                        write_d1;
logic                        write_d2;
replica_data                 out_data_r;

always_ff @(posedge clk) begin
    out_data <= out_data_r;
end

always_ff @(posedge clk) begin
    count_d1 <= count;
    write_d1 <= (command != NOP || count != 0);
    count_d2 <= count_d1;
    write_d2 <= write_d1;
end
always_ff @(posedge clk) begin
    if (write_d2) begin
        ram[count_d2] <= prev_data;
    end
    out_data_r <= ram[count];
end

always_ff @(posedge clk) begin
    if (reset) begin
        count <= '0;
    end else if (command != NOP) begin
        count <= count + 1;
    end else if ( count != '0) begin    
        if (count + 1 != city_num) begin
            count <= count + 1;
        end else begin
            count <= '0;
        end        
    end
end    

endmodule