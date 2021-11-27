module node_control
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    run_write,
    input  logic [23:0]             run_times,
    output logic                    running,
    input  logic                    random_ready,

    input  logic                    change_base_id,
    output logic [base_log-1:0]     or_rn_base_id,
    output logic [base_log-1:0]     tw_rn_base_id,
    output logic [base_log-1:0]     or_dd_base_id_P,
    output logic [base_log-1:0]     or_dd_base_id,
    output logic [base_log-1:0]     tw_dd_base_id,
    output logic [base_log-1:0]     or_rp_base_id_P,
    output logic [base_log-1:0]     or_rp_base_id,
    output logic [base_log-1:0]     tw_rp_base_id,
    output logic [base_log-1:0]     or_ex_base_id_P,
    output logic [base_log-1:0]     or_ex_base_id,
    output logic [base_log-1:0]     tw_ex_base_id,

    output logic                    opt_run,
    output logic                    or_opt_en,
    output logic                    tw_opt_en,

    output distance_command_t       or_distance_com,
    output distance_command_t       tw_distance_com,
    
    output logic                    exp_init,
    output logic                    exp_run,
    output logic                    exp_fin,
    output logic [16:0]             exp_recip,

    output logic                    update_minimum_distance    
);

logic  [4:0] cycle_cnt;

assign opt_fin  = (cycle_cnt == 19) && running && random_ready;
assign exp_fin  = (cycle_cnt == 18);
assign exp_init = (cycle_cnt ==  0) && running && random_ready;
assign opt_run  = (cycle_cnt ==  0) && running && random_ready;

always_ff @(posedge clk) begin
    if(reset)         cycle_cnt <= 'b0;
    else if(opt_run)  cycle_cnt <= 'b1;
    else if(opt_fin)  cycle_cnt <= 'b0;
    else if(running)  begin if(cycle_cnt != 19) cycle_cnt <= cycle_cnt + 1; end
    else              cycle_cnt <= 'b0;
end

always_ff @(posedge clk) begin
    if(reset) begin
        running <= 'b0;
    end else if (run_write) begin
        running <= 'b1;
    end else if(~or_opt_en && ~tw_opt_en && tw_ex_base_id == 0) begin
        running <= 'b0;
    end
end

logic tw_ex_opt_en;
always_ff @(posedge clk)begin
    if(reset)          tw_ex_opt_en <= 1'b0;
    else if(tw_opt_en) tw_ex_opt_en <= 1'b1;
    else if(!running)  tw_ex_opt_en <= 1'b0;
    update_minimum_distance <= (tw_ex_base_id == base_num - 1) && opt_run && tw_ex_opt_en;
end

logic [4:0][base_log-1:0] or_base_id, tw_base_id;

assign or_rn_base_id = or_base_id[0];
assign tw_rn_base_id = tw_base_id[0];

logic [23:0] opt_cnt;

always_ff @(posedge clk) begin
    if(reset)                                                                                   or_opt_en <= 'b0;
    else if (run_write)                                                                         or_opt_en <= 'b1;
    else if (opt_fin && or_opt_en && (or_base_id[0]==base_num-1) && (opt_cnt + 1 == run_times)) or_opt_en <= 'b0;

    if(reset)                                                                                   tw_opt_en <= 'b0;
    else if (opt_fin && or_opt_en && (or_base_id[0]==4))                                        tw_opt_en <= 'b1;
    else if (opt_fin && tw_opt_en && (tw_base_id[0]==base_num-1) && (opt_cnt + 1 == run_times)) tw_opt_en <= 'b0;

    if(reset)                                                                                   opt_cnt <= 0;
    else if (opt_fin && or_opt_en && (or_base_id[0]==4))                                        opt_cnt <= opt_cnt + 1;
    else if (opt_fin && or_opt_en && (or_base_id[0]==base_num-1) && (opt_cnt + 1 != run_times)) opt_cnt <= opt_cnt + 1;

end

always_ff @(posedge clk) begin
    if(reset)                                         or_base_id <= '0;
    else if(run_write)                                or_base_id <= '0;
    else if(change_base_id || opt_fin && or_opt_en)
        if(or_base_id[0] != base_num - 1)             or_base_id[0] <= or_base_id[0]+1;
        else                                          or_base_id[0] <= '0;

    if(reset)                                         tw_base_id <= '0;
    else if(run_write)                                tw_base_id <= -5;
    else if(change_base_id || opt_fin && (or_opt_en || tw_opt_en))
        if(tw_base_id[0] != base_num - 1)             tw_base_id[0] <= tw_base_id[0]+1;
        else                                          tw_base_id[0] <= '0;

    if(run_write)
        for(int i=1; i<5; i+=1) begin or_base_id[i] <= -i; tw_base_id[i] <= -i-5; end
    else if(opt_run)
        for(int i=1; i<5; i+=1) begin or_base_id[i] <= or_base_id[i-1]; tw_base_id[i] <= tw_base_id[i-1]; end
end

always_ff @(posedge clk) begin
    if(reset)                             begin or_dd_base_id_P <= 0;
                                                or_dd_base_id   <= 0;                 tw_dd_base_id   <= 0;
                                                or_rp_base_id_P <= 0;
                                                or_rp_base_id   <= 0;                 tw_rp_base_id   <= 0;
                                                or_ex_base_id_P <= 0;
                                                or_ex_base_id   <= 0;                 tw_ex_base_id   <= 0;
    end else if(running) begin
        if(opt_fin)                       begin or_dd_base_id_P <= or_dd_base_id;
                                                or_dd_base_id   <= or_base_id[1];     tw_dd_base_id   <= tw_base_id[1];
                                                or_rp_base_id_P <= or_rp_base_id;
                                                or_rp_base_id   <= or_base_id[3];     tw_rp_base_id   <= tw_base_id[3];
                                                or_ex_base_id_P <= or_ex_base_id;
                                                or_ex_base_id   <= or_base_id[4];     tw_ex_base_id   <= tw_base_id[4]; end
    end else if(change_base_id) begin
        if(or_base_id[0] != base_num - 1) begin or_rp_base_id_P <= or_base_id[0] + 1;
                                                or_rp_base_id   <= or_base_id[0] + 1; tw_rp_base_id   <= tw_base_id[0] + 1;
                                                or_ex_base_id_P <= or_base_id[0] + 1;
                                                or_ex_base_id   <= or_base_id[0] + 1; tw_ex_base_id   <= tw_base_id[0] + 1; end
        else                              begin or_rp_base_id_P <= '0;
                                                or_rp_base_id   <= '0;                tw_rp_base_id   <= '0;
                                                or_ex_base_id_P <= '0;
                                                or_ex_base_id   <= '0;                tw_ex_base_id   <= '0; end
    end
end


always_ff @(posedge clk) begin
    case(cycle_cnt)
        1:        or_distance_com <= {KN , ZERO};
        2:        or_distance_com <= {KM , MNS};
        3:        or_distance_com <= {KP , PLS};
        4:        or_distance_com <= {KN , MNS};
        5:        or_distance_com <= {LN , PLS};
        6:        or_distance_com <= {LP , MNS};
        7:        or_distance_com <= {KN , PLS};
        default:  or_distance_com <= {KN , DNOP};
    endcase
    case(cycle_cnt)
        1:        tw_distance_com <= {KN , ZERO};
        2:        tw_distance_com <= {KM , MNS};
        3:        tw_distance_com <= {LM , PLS};
        4:        tw_distance_com <= {LN , MNS};
        5:        tw_distance_com <= {KN , PLS};
        default:  tw_distance_com <= {KN , DNOP};
    endcase
end

logic [3:0]        exp_count;

always_ff @(posedge clk)begin
    if(reset) begin
        exp_run <= 'b0;
        exp_count <= 'd0;
    end else if(exp_init) begin
        exp_run <= 'b1;
        exp_count <= 'd14;
    end else if(exp_count >= 1) begin
        exp_run <= 'b1;
        exp_count <= exp_count - 1;
    end else if(exp_count == 0) begin
        exp_run <= 'b0;
        exp_count <= 'd0;
    end
end

always_ff @(posedge clk)
    if(exp_init || exp_run)
        case(exp_count)
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