module top
    import replica_pkg::*;
#(
    parameter replica_num = 32
)
(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      set_random,
    input  logic [63:0]               random_seed,
    input  logic                      random_run,
    input  logic                      run_command,
    input  logic                      set_command,
    input  logic                      run_distance,
    input  exchange_command_t         c_exchange,
    input  exchange_command_t         c_metropolis,
    input  opt_command_t [replica_num-1:0] opt_com,
    input  logic                      distance_write,
    input  logic [city_num_log*2-1:0] distance_w_addr,
    input  distance_data_t            distance_w_data,
    input  total_data_t               total_in_data,
    output total_data_t               total_out_data,
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

logic [replica_num-1:0]   random_init;

always_ff @(posedge clk)begin
    if(reset) random_init <= 'b0;
    else      random_init <= {random_init,set_random};
end
    
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

opt_command_t [replica_num-1:0]            opt_command;
integer count;
integer opt_count;
logic opt_run;
logic dist_run;
always_ff @(posedge clk)begin
    if(reset)begin
        for(int i=0; i<replica_num; i+=1)begin
            opt_command[i] <= THR;
        end
    end else if(run_command)begin
        count                  <= 0;
        opt_count              <= 0;
        opt_run                <= 1;
    end else if(opt_run)begin
        count                  <= count + 1;
        if(count == 5)begin
            opt_run            <= '0;
            for(int i=0; i<replica_num; i++)begin
                opt_command[i] <= THR;
            end
        end
    end else if(run_distance)begin
        opt_command             <= opt_com;
        dist_run                <= 1;
        count                   <= 0;
    end else if(dist_run)begin
        count                   <= count + 1;
        if(count == 20) begin
            dist_run           <= 0;
        end
    end else if(random_run)begin
        opt_command            <= opt_com;
    end
end

opt_command_t opt_com_a;
always_comb begin
    opt_com_a = THR;
    for(int i=0; i<replica_num; i++) begin
        if(opt_com[i] == OR0 || opt_com[i] == OR1) begin opt_com_a = OR0; break; end
        else if(opt_com[i] == TWO)                 begin opt_com_a = TWO; break; end
    end
end

always_ff @(posedge clk)begin
    if (dist_run && opt_com_a == OR0)
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
    else if (dist_run && opt_com_a == TWO)
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

logic             [replica_num+1:0]  ordering_valid;
replica_data_t    [replica_num+1:0]  ordering_data;
total_data_t      [replica_num+1:0]  dis_data;

assign ordering_valid[0] = in_valid_d3;
assign ordering_data[0]  = in_data_d3;
assign dis_data[0] = total_in_data;
assign total_out_data = dis_data[replica_num];

always_comb
    for(int i=0; i<8; i++) ordering_out_data[i][6:0] = ordering_data[replica_num][7-i][6:0];

exchange_command_t [31:0] c_metropolis_w;
always_comb
    case(c_metropolis)
        PREV: for(int i=0; i<32; i++) c_metropolis_w[i] = c_metropolis;
        SELF: for(int i=0; i<32; i++) c_metropolis_w[i] = c_metropolis;
        FOLW: for(int i=0; i<32; i++) if(c_exchange_d1[i]==SELF) c_metropolis_w[i] = NOP; else c_metropolis_w[i] = c_exchange_d1[i];
        default: for(int i=0; i<32; i++) c_metropolis_w[i] = NOP;
    endcase
    
for (genvar g = 0; g < replica_num; g += 1) begin
    replica replica
    (
        .clk             ( clk                 ),
        .reset           ( reset               ),
        .random_init     ( random_init[g]      ),
        .random_seed     ( random_seed         ),
        .random_run      ( random_run          ),
        .c_exchange      ( c_exchange_d1[g]    ),
        .c_metropolis    ( c_metropolis_w[g]   ),
        .c_distance      ( c_distance          ),
        .opt_command     ( opt_command[g]      ),
        .rbank           ( rbank               ),
        .distance_write  ( distance_write      ),
        .distance_w_addr ( distance_w_addr     ),
        .distance_w_data ( distance_w_data     ),

        .prev_dis_data   ( dis_data[g]         ),
        .folw_dis_data   ( dis_data[g+2]       ),
        .out_dis_data    ( dis_data[g+1]       ),
        
        .prev_ord_valid  ( ordering_valid[g]   ),
        .prev_ord_data   ( ordering_data[g]    ),
        .folw_ord_valid  ( ordering_valid[g+2] ),
        .folw_ord_data   ( ordering_data[g+2]  ),
        .out_ord_valid   ( ordering_valid[g+1] ),
        .out_ord_data    ( ordering_data[g+1]  )
    );
end

endmodule