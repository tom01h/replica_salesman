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
    output opt_command_t            opt_command,
    output logic                    random_run,
    output distance_command_t       distance_com,
    output logic                    metropolis_run,
    output logic                    replica_run,
    output logic                    exchange_run,
    output logic                    exchange_bank,
    input  logic                    exchange_shift,
    output logic                    exp_init,
    output logic                    exp_run,
    output logic [16:0]             exp_recip
);

logic        run;
logic [23:0] run_times_reg;
logic [23:0] run_cnt;
logic        cycle_finish;

always_ff @(posedge clk) begin
    if(reset) begin
        run <= 'b0;
        running <= 'b0;
        run_cnt <= 'b0;
        opt_command <= THR;
    end else if (run_write) begin
        run <= 'b1;
        running <= 'b1;
        run_times_reg <= run_times;
        opt_command <= OR1;
    end else if(cycle_finish) begin
        if((run_cnt + 1) != run_times_reg) begin
            run <= 'b1;
            run_cnt <= run_cnt + 1;
            if(opt_command == OR1) opt_command <= TWO;
            else                   opt_command <= OR1;
        end else begin
            running <= 'b0;
            opt_command <= THR;
        end
    end else
        run <= 'b0;
end

logic [6:0]  cycle_cnt;

assign random_run     = run;
assign distance_run   = (cycle_cnt == 20);
assign metropolis_run = (cycle_cnt == 58);
assign replica_run    = (cycle_cnt == 78);
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

assign exp_init = (cycle_cnt == 40) || (cycle_cnt == 60);
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