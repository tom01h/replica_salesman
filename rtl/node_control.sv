module node_control
    import replica_pkg::*;
#(
    parameter id = 0,
    parameter replica_num = 32
)
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    run_write,
    input  logic [23:0]             run_times,
    output logic                    running,

    output logic                    opt_run,
    output opt_command_t            opt_com,
    output opt_command_t            opt_command,

    output distance_command_t       or_distance_com,
    output logic                    or_metropolis_run,
    output logic                    or_replica_run,
    output logic                    or_exchange_run,

    output distance_command_t       tw_distance_com,
    output logic                    tw_metropolis_run,
    output logic                    tw_replica_run,
    output logic                    tw_exchange_run,
    
    input  logic                    exchange_shift,
    output logic                    exp_init,
    output logic                    exp_run,
    output logic                    exp_fin,
    output logic [16:0]             exp_recip
);

logic        run;
logic [23:0] run_times_reg;
logic [23:0] run_cnt;
logic        cycle_finish;
logic  [7:0] cycle_cnt;

logic     fin_tmp;

always_ff @(posedge clk) begin
    fin_tmp <= 'b0;
    if(reset) begin
        run <= 'b0;
        running <= 'b0;
        run_cnt <= 'b0;
        opt_com <= THR;
        opt_command <= THR;
    end else if (run_write) begin
        run <= 'b1;
        running <= 'b1;
        run_times_reg <= run_times;
        opt_com <= OR1;
        opt_command <= OR1;
    end else if((cycle_cnt == 19) || (cycle_cnt == 119)) begin
        opt_com <= THR;
    end else if(cycle_cnt == 99) begin
        opt_com <= TWO;
        opt_command <= TWO;
    end else if(cycle_finish) begin
        if((run_cnt + 2) != run_times_reg) begin
            run <= 'b1;
            run_cnt <= run_cnt + 2;
            opt_com <= OR1;
            opt_command <= OR1;
        end else begin
            fin_tmp <= 'b1;
            running <= 'b0;
            opt_com <= THR;
            opt_command <= THR;
        end
    end else
        run <= 'b0;
end

assign opt_run        = run || (cycle_cnt % 20 == 0) && (cycle_cnt != 0);// || fin_tmp;
assign exp_fin        = cycle_cnt % 20 == 18;

assign distance_run   = (cycle_cnt == 20) || (cycle_cnt == 120);
assign exp_init       = (cycle_cnt == 40) || (cycle_cnt == 60) || (cycle_cnt == 140) || (cycle_cnt == 160);
assign or_metropolis_run = (cycle_cnt ==  58);
assign tw_metropolis_run = (cycle_cnt == 158);
assign or_replica_run    = (cycle_cnt ==  78);
assign tw_replica_run    = (cycle_cnt == 178);
assign or_exchange_run   = (cycle_cnt ==  80);
assign tw_exchange_run   = (cycle_cnt == 180);
assign cycle_finish   = (cycle_cnt == 199);

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
            0:                                or_distance_com <= {KN , ZERO};
            1:                                or_distance_com <= {KM , MNS};
            2:                                or_distance_com <= {KP , PLS};
            3:                                or_distance_com <= {KN , MNS};
            4:                                or_distance_com <= {LN , PLS};
            5:                                or_distance_com <= {LP , MNS};
            6:                                or_distance_com <= {KN , PLS};
            default:                          or_distance_com <= {KN , DNOP};
        endcase
    else                                      or_distance_com <= {KN , DNOP};
    if (dist_run && opt_command == TWO)
        case(dist_count)
            0:                                tw_distance_com <= {KN , ZERO};
            1:                                tw_distance_com <= {KM , MNS};
            2:                                tw_distance_com <= {LM , PLS};
            3:                                tw_distance_com <= {LN , MNS};
            4:                                tw_distance_com <= {KN , PLS};
            default:                          tw_distance_com <= {KN , DNOP};
        endcase
    else                                      tw_distance_com <= {KN , DNOP};
end

logic [3:0]        exp_count;
logic [3:0]        rom_addr;
assign rom_addr = exp_count - 1;

always_ff @(posedge clk)begin
    if(reset) begin
        exp_run <= 'b0;
        exp_count <= 'd0;
    end else if(exp_init) begin
        exp_run <= 'b1;
        exp_count <= 'd15;
    end else if(exp_count >= 2) begin
        exp_run <= 'b1;
        exp_count <= exp_count - 1;
    end else if(exp_count == 1) begin
        exp_run <= 'b0;
        exp_count <= 'd0;
    end
end

always_ff @(posedge clk)
    if(exp_init || exp_run)
        case(rom_addr)
            'd0  : exp_recip <= (1<<15) / 15;
            'd1  : exp_recip <= (1<<15) / 1;
            'd2  : exp_recip <= (1<<15) / 2;
            'd3  : exp_recip <= (1<<15) / 3;
            'd4  : exp_recip <= (1<<15) / 4;
            'd5  : exp_recip <= (1<<15) / 5;
            'd6  : exp_recip <= (1<<15) / 6;
            'd7  : exp_recip <= (1<<15) / 7;
            'd8  : exp_recip <= (1<<15) / 8;
            'd9  : exp_recip <= (1<<15) / 9;
            'd10 : exp_recip <= (1<<15) / 10;
            'd11 : exp_recip <= (1<<15) / 11;
            'd12 : exp_recip <= (1<<15) / 12;
            'd13 : exp_recip <= (1<<15) / 13;
            'd14 : exp_recip <= (1<<15) / 14;
            'd15 : exp_recip <= (1<<15) / 15;
        endcase

endmodule