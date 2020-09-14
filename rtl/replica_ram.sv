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

always_ff @(posedge clk) begin
    if (command != NOP || count != 0) begin
        ram[count] <= prev_data;
    end
    out_data <= ram[count];
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