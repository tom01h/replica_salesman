module replica_ram
    import replica_pkg::*;
(
    input  logic             clk,
    input  logic             reset,
    input  replica_command_t command,
    input  logic             wbank,
    input  replica_data_t    prev_data,
    input  replica_data_t    folw_data,
    output logic             out_valid,
    output replica_data_t    out_data
);

replica_data_t [1:0][city_num-1:0]  ram;

logic               [city_num-1:0]  count;
logic               [city_num-1:0]  count_d1,   count_d2;
logic                               write_d1,   write_d2;
replica_command_t                   command_d1, command_d2;
logic                               rbank_d1,   rbank_d2;

replica_data_t                      write_data;
assign write_data = (command_d2 == PREV) ? prev_data : 
                    (command_d2 == FOLW) ? folw_data : out_data;

logic                             out_valid_r;
replica_data_t                    out_data_r;
always_ff @(posedge clk) begin
    out_valid <= out_valid_r;
    out_data  <= out_data_r;
end

always_ff @(posedge clk) begin
    count_d1 <= count;
    write_d1 <= (command != NOP || count != 0);
    if (command != NOP)
        command_d1 <= command;
    rbank_d1   <= ~wbank;
    count_d2   <= count_d1;
    write_d2   <= write_d1;
    command_d2 <= command_d1;
    rbank_d2   <= rbank_d1;
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