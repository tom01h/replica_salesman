module replica_ram
    import replica_pkg::*;
(
    input  logic           clk,
    input  logic           reset,
    input  replica_command command,
    input  logic           wbank,
    input  replica_data    prev_data,
    input  replica_data    folw_data,
    output logic           out_valid,
    output replica_data    out_data
);

replica_data [1:0][city_num-1:0]  ram;

logic             [city_num-1:0]  count;
logic             [city_num-1:0]  count_d1, count_d2;
logic                             write_d1, write_d2;
logic                             sel_d1,   sel_d2;
logic                             rbank_d1, rbank_d2;

replica_data                      write_data;
assign write_data = (sel_d2) ? prev_data : folw_data;

logic                             out_valid_r;
replica_data                      out_data_r;
always_ff @(posedge clk) begin
    out_valid <= out_valid_r;
    out_data  <= out_data_r;
end

always_ff @(posedge clk) begin
    count_d1 <= count;
    write_d1 <= (command != NOP || count != 0);
    if (command != NOP)
        sel_d1   <= (command == PREV);
    rbank_d1 <= ~wbank;
    count_d2 <= count_d1;
    write_d2 <= write_d1;
    sel_d2   <= sel_d1;
    rbank_d2 <= rbank_d1;
end

always_ff @(posedge clk) begin
    if (write_d2) begin
        ram[rbank_d2][count_d2] <= write_data;
    end
    out_data_r <= ram[wbank][count];
end

always_ff @(posedge clk) begin
    if (reset) begin
        count       <= '0;
        out_valid_r <= '0;
    end else if (command != NOP) begin
        count <= count + 1;
        out_valid_r <= '1;
    end else if ( count != '0) begin
        out_valid_r <= '1;
        if (count + 1 != city_num) begin
            count <= count + 1;
        end else begin
            count <= '0;
        end
    end else begin
        out_valid_r <= '0;
    end
end    

endmodule