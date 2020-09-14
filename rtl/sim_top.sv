module sim_top
    import replica_pkg::*;
(
    input  logic           clk,
    input  logic           reset
);

typedef enum logic [2:0] {
    RST  = 0,
    SFTI = 1,
    SWAP = 2,
    SFTO = 3,
    FIN  = 4
} sim_state_t;

sim_state_t sim_state;
logic shift_start;
logic shift_run;
integer count;

always_ff @(posedge clk) begin
    if (reset) begin
        sim_state <= RST;
        shift_start <= '0;
    end else begin
        case(sim_state)
            RST: begin
                sim_state   <= SFTI;
                shift_start <= '1;
                count   <= 0;
            end
            SFTI: if (~shift_run & ~shift_start) begin
                if (count < 10) begin
                    count <= count + 1;
                end else begin
                    sim_state   <= SWAP;
                    count   <= 0;
                end
            end else begin
                shift_start <= '0;
            end    
            SWAP: if (count < 10) begin
                count <= count + 1;
            end else begin
                sim_state   <= SFTO;
                shift_start <= '1;
                count   <= 0;
            end
            SFTO: if (~shift_run & ~shift_start) begin
                sim_state   <= FIN;
                count   <= 0;
            end else begin
                shift_start <= '0;
            end    
            FIN: if (count < 10) begin
                count <= count + 1;
            end else begin
                $finish();
            end    
        endcase
    end
end    

integer cycle_count;
integer replica_count;

replica_data          in_data;
replica_command [1:0] in_command;

always_ff @(posedge clk) begin
    if (reset) begin
        cycle_count   <= 0;
        replica_count <= 0;
        shift_run     <= '0;
    end else if (shift_start) begin
        cycle_count   <= 0;
        replica_count <= 0;
        shift_run     <= '1;
    end else if (shift_run) begin
        if ((cycle_count + 1) % city_num == 0) begin
            cycle_count   <= 0;
            if ((replica_count + 1) < replica_num) begin
                replica_count <= replica_count + 1;
            end else begin
                replica_count <= 0;
                shift_run <= '0;
            end
        end else begin
            cycle_count   <= cycle_count + 1;
        end
    end
end
        
always_ff @(posedge clk) begin
    if (sim_state == SFTI && shift_run) begin
        for (int i = 0; i < 8; i += 1) begin
            in_data[i] <= ((replica_count + cycle_count) % city_num) * 8 + i;
        end
    end else begin
        in_data <= 'x;
    end    
end

always_comb begin
    if (cycle_count == 0 && shift_run)        in_command = {PREV, PREV};
    else if (sim_state == SWAP && count == 0) in_command = {PREV, FOLW};
    else                                      in_command = {NOP,  NOP};
end        

replica_data    [replica_num-1:0]  folw_data;
replica_data    [replica_num+1:0]  out_data;
replica_command [1:0]              command;
replica_data                       in_data_d1;
replica_data                       in_data_d2;

always_ff @(posedge clk) begin
    if (reset) begin
        command     <= NOP;
        in_data_d1  <= 'x;
        in_data_d2  <= 'x;
    end else begin
        command     <= in_command;
        in_data_d1  <= in_data;
        in_data_d2  <= in_data_d1;
    end        
end

assign out_data[0] = in_data_d2;

for (genvar g = 0; g < replica_num; g += 1) begin
    replica_ram replica_ram
    (
        .clk         ( clk           ),
        .reset       ( reset         ),
        .command     ( command[g%2]  ),
        .prev_data   ( out_data[g]   ),
        .folw_data   ( out_data[g+2] ),
        .out_data    ( out_data[g+1] )
    );
end

// for waveform

logic [6:0]     w_in_data [7:0];
logic [6:0]     w_out_data [7:0];

always_comb begin
    for (int i = 0; i < 8; i += 1) begin
        w_in_data[i]  = in_data[i];
        w_out_data[i] = out_data[4][i];
    end
end

endmodule
