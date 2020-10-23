module sim_top
    import replica_pkg::*;
(
    input  logic           clk,
    input  logic           reset
);

parameter replica_num = 4;

typedef enum logic [2:0] {
    RST  = 0,
    SFTI = 1,
    DIST = 2,
    SWAP = 3,
    SFTO = 4,
    FIN  = 5
} sim_state_t;

sim_state_t sim_state;
logic shift_start;
logic shift_run;
integer count;

always_ff @(posedge clk) begin
    if (reset) begin
        sim_state <= RST;
        shift_start <= '0;
        count   <= 0;
    end else begin
        case(sim_state)
            RST:
                if (count < (city_num+1)*city_num/2) begin
                    count <= count + 1;
                end else begin
                    sim_state   <= SFTI;
                    shift_start <= '1;
                    count   <= 0;
                end
            SFTI:
                if (shift_start) begin
                    shift_start <= '0;
                end else if(~shift_run) begin
                    if (count < 10) begin
                        count <= count + 1;
                    end else begin
                        sim_state   <= DIST;
                        count   <= 0;
                    end
                end    
            DIST:
                if (count < 20) begin
                    count <= count + 1;
                end else begin
                    sim_state   <= SWAP;
                    count   <= 0;
                end
            SWAP:
                if (count < 10) begin
                    count <= count + 1;
                end else begin
                    sim_state   <= SFTO;
                    shift_start <= '1;
                    count   <= 0;
                end
            SFTO:
                if (shift_start) begin
                    shift_start <= '0;
                end else if (~shift_run) begin
                    sim_state   <= FIN;
                    count   <= 0;
                end    
            FIN:
                if (count < 10) begin
                    count <= count + 1;
                end else begin
                    $finish();
                end    
        endcase
    end
end    

logic                      distance_write;
logic [city_num_log*2-1:0] distance_w_addr;
distance_data_t            distance_w_data;

always_ff @(posedge clk) begin
    if(sim_state == RST && ~reset)begin
        distance_write <= '1;
        distance_w_addr <= count;
        distance_w_data <= count;
    end else begin
        distance_write <= '0;
    end    
end
    
integer cycle_count;
integer replica_count;

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
        if ((cycle_count + 1) % city_div == 0) begin
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

logic                    in_valid;
replica_data_t           in_data;
exchange_command_t [1:0] in_exchange;
distance_command_t       in_distance;
opt_t [replica_num-1:0]  in_opt;

always_ff @(posedge clk) begin
    if (sim_state == SFTI && shift_run) begin
        in_valid <= '1;
        for (int i = 0; i < 8; i += 1) begin
            //in_data[i] <= ((replica_count + cycle_count) % city_div) * 8 + i;
            in_data[i] <= ((cycle_count) % city_div) * 8 + i;
        end
    end else begin
        in_valid <= '0;
        in_data <= 'x;
    end    
end

always_comb begin
    if (cycle_count == 0 && shift_run)        in_exchange = {PREV, PREV};
    else if (sim_state == SWAP && count == 0) in_exchange = {SELF, SELF};
    //else if (sim_state == SWAP && count == 0) in_exchange = {PREV, FOLW};
    else                                      in_exchange = {NOP,  NOP};
    if (sim_state == DIST && (in_opt[0].command == OR0 || in_opt[0].command == OR1))
        case(count)
            0:                                in_distance = {KN , ZERO};
            1:                                in_distance = {KM , MNS};
            2:                                in_distance = {KP , PLS};
            3:                                in_distance = {KN , MNS};
            4:                                in_distance = {LN , PLS};
            5:                                in_distance = {LP , MNS};
            6:                                in_distance = {KN , PLS};
            default:                          in_distance = {KN , DNOP};
        endcase
    else if (sim_state == DIST && in_opt[0].command == TWO)
        case(count) 
            0:                                in_distance = {KN , ZERO};
            1:                                in_distance = {KM , MNS};
            2:                                in_distance = {LM , PLS};
            3:                                in_distance = {LN , MNS};
            4:                                in_distance = {KN , PLS};
            default:                          in_distance = {KN , DNOP};
        endcase
    else                                      in_distance = {KN , DNOP};
end        

always_comb begin
    //if(0)begin
    if(sim_state == DIST || sim_state == SWAP)begin
        for (int i = 0; i < replica_num; i += 1) begin
            //in_opt[i].command = OR0;
            //in_opt[i].command = OR1;
            in_opt[i].command = TWO;
        end
        /*in_opt[0].K = 0; in_opt[0].L = 10;
        in_opt[1].K = 9; in_opt[1].L = 10;
        in_opt[2].K = 9; in_opt[2].L = 24;
        in_opt[3].K = 9; in_opt[3].L = 31;/**/
        /*in_opt[0].K = 25; in_opt[0].L = 6;
        in_opt[1].K = 25; in_opt[1].L = 9;
        in_opt[2].K = 11; in_opt[2].L = 9;
        in_opt[3].K = 31; in_opt[3].L = 0;/**/
        in_opt[0].K = 8; in_opt[0].L = 27;
        in_opt[1].K = 9; in_opt[1].L = 20;
        in_opt[2].K = 2; in_opt[2].L = 19;
        in_opt[3].K = 9; in_opt[3].L = 14;/**/
    end else begin
        for (int i = 0; i < replica_num; i += 1) begin
            in_opt[i].command = THR;
        end    
    end        
end

replica_data_t    [replica_num-1:0]  folw_data;
logic             [replica_num+1:0]  out_valid;
replica_data_t    [replica_num+1:0]  out_data;
exchange_command_t [1:0]             c_exchange;
distance_command_t                   c_distance;
opt_t [replica_num-1:0]              opt;
logic                                in_valid_d1;
logic                                in_valid_d2;
logic                                in_valid_d3;
replica_data_t                       in_data_d1;
replica_data_t                       in_data_d2;
replica_data_t                       in_data_d3;
logic                                rbank;

always_ff @(posedge clk) begin
    opt <= in_opt;
    if (reset) begin
        c_exchange  <= NOP;
        c_distance  <= '0;
        in_valid_d1 <= '0;
        in_valid_d2 <= '0;
        in_valid_d3 <= '0;
        in_data_d1  <= 'x;
        in_data_d2  <= 'x;
        in_data_d3  <= 'x;
        rbank       <= '0;
    end else begin
        c_exchange  <= in_exchange;
        c_distance  <= in_distance;
        in_valid_d1 <= in_valid;
        in_valid_d2 <= in_valid_d1;
        in_valid_d3 <= in_valid_d2;
        in_data_d1  <= in_data;
        in_data_d2  <= in_data_d1;
        in_data_d3  <= in_data_d2;
        if (in_exchange != NOP) rbank <= ~rbank;
    end
end

assign out_valid[0] = in_valid_d3;
assign out_data[0]  = in_data_d3;

for (genvar g = 0; g < replica_num; g += 1) begin
    replica replica
    (
        .clk             ( clk             ),
        .reset           ( reset           ),
        .c_exchange      ( c_exchange[g%2] ),
        .c_distance      ( c_distance      ),
        .opt             ( opt[g]          ),
        .rbank           ( rbank           ),
        .distance_write  ( distance_write  ),
        .distance_w_addr ( distance_w_addr ),
        .distance_w_data ( distance_w_data ),
        .prev_valid      ( out_valid[g]    ),
        .prev_data       ( out_data[g]     ),
        .folw_valid      ( out_valid[g+2]  ),
        .folw_data       ( out_data[g+2]   ),
        .out_valid       ( out_valid[g+1]  ),
        .out_data        ( out_data[g+1]   )
    );
end

// for waveform

logic [6:0]     w_in_data [7:0];
logic [6:0]     w_out_data [7:0];

always_comb begin
    for (int i = 0; i < 8; i += 1) begin
        w_in_data[i]  = in_data_d2[i];
        w_out_data[i] = out_data[4][i];
    end
end

endmodule
