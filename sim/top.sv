module top
    import replica_pkg::*;
(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      run_command,
    input  logic                      set_command,
    input  logic                      run_distance,
    input  exchange_command_t         c_exchange,
    input  logic                      set_opt,
    input  opt_command                opt_com,
    input  logic [6:0]                K,
    input  logic [6:0]                L,
    input  logic                      distance_write,
    input  logic [city_num_log*2-1:0] distance_w_addr,
    input  distance_data_t            distance_w_data,
    input  logic                      ordering_in_valid,
    input  logic [7:0][7:0]           ordering_in_data,
    output logic                      ordering_out_valid,
    output logic [7:0][7:0]           ordering_out_data

);

distance_command_t        c_distance;
logic                     rbank;
exchange_command_t [31:0] c_exchange_l, c_exchange_d1;
logic                     in_valid_d1,   in_valid_d2,   in_valid_d3;
replica_data_t            in_data_d1,    in_data_d2,    in_data_d3;
integer com_count;

always_ff @(posedge clk)begin
    if(reset)begin
        rbank <= '0;
        c_exchange_d1 <= '0;
        com_count  <= '0;
    end else if(set_command)begin
        c_exchange_l[com_count] <= c_exchange;
        com_count  <= com_count + 1;
    end else begin
        if(run_command)begin
            rbank <= ~rbank;
            if(c_exchange != 0)begin
                for(int i = 0; i < 32; i++)begin
                    c_exchange_d1[i] <= c_exchange;
                end
            end else begin
                com_count  <= '0;
                c_exchange_d1 <= c_exchange_l;
            end    
        end else begin
            c_exchange_d1 <= '0;
        end    
        in_valid_d1 <= ordering_in_valid;
        for(int i=0; i<8; i++) in_data_d1[i][6:0] <= ordering_in_data[7-i][6:0];
        in_valid_d2 <= in_valid_d1;
        in_data_d2 <= in_data_d1;
        in_valid_d3 <= in_valid_d2;
        in_data_d3 <= in_data_d2;
    end
end

logic signed [31:0][20:0]        delta_distance;
opt_t  [31:0] opt;
integer count;
integer opt_count;
integer dist_count;
logic opt_run;
logic dist_run;
always_ff @(posedge clk)begin
    if(set_opt)begin
        opt[opt_count].command <= opt_com;
        opt[opt_count].K       <= K;
        opt[opt_count].L       <= L;
        opt_count              <= opt_count + 1;
    end else if(run_command)begin
        count                  <= 0;
        opt_count              <= 0;
        dist_count             <= 0;
        opt_run                <= 1;
    end else if(opt_run)begin
        count                  <= count + 1;
        if(count == 5)begin
            opt_run            <= '0;
            for(int i=0; i<32; i++)begin
                opt[i].command <= 0;
            end
        end
    end else if(run_distance)begin
        opt[dist_count].command <= opt_com;
        opt[dist_count].K       <= K;
        opt[dist_count].L       <= L;
        dist_run                <= 1;
        count                   <= 0;
    end else if(dist_run)begin
        count                   <= count + 1;
        if(count == 18) begin
            dist_run           <= 0;
            dist_count         <= dist_count + 1;
            $display("%d", delta_distance[dist_count]);
        end
    end
end

always_ff @(posedge clk)begin
    if (dist_run && (opt_com == OR0 || opt_com == OR1))
        case(count)
            0:                                c_distance = {KN , ZERO};
            1:                                c_distance = {KM , MNS};
            2:                                c_distance = {KP , PLS};
            3:                                c_distance = {KN , MNS};
            4:                                c_distance = {LN , PLS};
            5:                                c_distance = {LP , MNS};
            6:                                c_distance = {KN , PLS};
            default:                          c_distance = {KN , DNOP};
        endcase
    else if (dist_run && opt_com == TWO)
        case(count)
            0:                                c_distance = {KN , ZERO};
            1:                                c_distance = {KM , MNS};
            2:                                c_distance = {LM , PLS};
            3:                                c_distance = {LN , MNS};
            4:                                c_distance = {KN , PLS};
            default:                          c_distance = {KN , DNOP};
        endcase
    else                                      c_distance = {KN , DNOP};
end

logic             [33:0]  ordering_valid;
replica_data_t    [33:0]  ordering_data;

assign ordering_valid[0] = in_valid_d3;
assign ordering_data[0]  = in_data_d3;

always_comb
    for(int i=0; i<8; i++) ordering_out_data[i][6:0] = ordering_data[32][7-i][6:0];

for (genvar g = 0; g < 32; g += 1) begin
    replica replica
    (
        .clk             ( clk                 ),
        .reset           ( reset               ),
        .c_exchange      ( c_exchange_d1[g]    ),
        .c_distance      ( (dist_count == g) ? c_distance : {KN , DNOP} ),
        .opt             ( opt[g]              ),
        .rbank           ( rbank               ),
        .distance_write  ( distance_write      ),
        .distance_w_addr ( distance_w_addr     ),
        .distance_w_data ( distance_w_data     ),
        .prev_valid      ( ordering_valid[g]   ),
        .prev_data       ( ordering_data[g]    ),
        .folw_valid      ( ordering_valid[g+2] ),
        .folw_data       ( ordering_data[g+2]  ),
        .out_valid       ( ordering_valid[g+1] ),
        .out_data        ( ordering_data[g+1]  ),
        .delta_distance  ( delta_distance[g]   )
    );
end

endmodule