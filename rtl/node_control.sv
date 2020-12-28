module node_control
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    run,
    input  opt_command_t            opt_command,
    output logic                    random_run,
    output distance_command_t       distance_com,
    output logic                    metropolis_run,
    output logic                    replica_run,
    output logic                    exchange_run,
    output logic                    exchange_bank,
    input  logic                    exchange_shift
);

logic [6:0] cycle_cnt;
logic       cycle_finish;
logic       run_distance;

assign random_run     = run;
assign distance_run   = (cycle_cnt == 20);
assign metropolis_run = (cycle_cnt == 40);
assign replica_run    = (cycle_cnt == 60);
assign exchange_run   = (cycle_cnt == 80);
assign cycle_finish   = (cycle_cnt == 100);

always_ff @(posedge clk) begin
    if(reset)               cycle_cnt <= 'b0;
    else if(run)            cycle_cnt <= 'b1;
    else if(cycle_finish)   cycle_cnt <= 'b0;
    else if(cycle_cnt != 0) cycle_cnt <= cycle_cnt + 1;
end

logic       dist_run;
logic [4:0] dist_count;

always_ff @(posedge clk) begin
    if(distance_run)begin
        dist_run                <= 1;
        dist_count              <= 0;
    end else if(dist_run)begin
        dist_count              <= dist_count + 1;
        if(dist_count == 20) begin
            dist_run           <= 0;
        end
    end
end

always_ff @(posedge clk)begin
    if (dist_run && opt_command == OR1)
        case(dist_count)
            0:                                distance_com = {KN , ZERO};
            1:                                distance_com = {KM , MNS};
            2:                                distance_com = {KP , PLS};
            3:                                distance_com = {KN , MNS};
            4:                                distance_com = {LN , PLS};
            5:                                distance_com = {LP , MNS};
            6:                                distance_com = {KN , PLS};
            default:                          distance_com = {KN , DNOP};
        endcase
    else if (dist_run && opt_command == TWO)
        case(dist_count)
            0:                                distance_com = {KN , ZERO};
            1:                                distance_com = {KM , MNS};
            2:                                distance_com = {LM , PLS};
            3:                                distance_com = {LN , MNS};
            4:                                distance_com = {KN , PLS};
            default:                          distance_com = {KN , DNOP};
        endcase
    else                                      distance_com = {KN , DNOP};
end

always_ff @(posedge clk)begin
    if(reset)                exchange_bank <= '0;
    else if(exchange_run)    exchange_bank <= ~exchange_bank;
    else if(exchange_shift)  exchange_bank <= ~exchange_bank;
end
            
endmodule