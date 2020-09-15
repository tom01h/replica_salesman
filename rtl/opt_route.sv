module opt_route
    import replica_pkg::*;
(
    input  logic                clk,
    input  logic                reset,
    input  replica_command_t    command,
    input  opt_t                opt,
    output logic [city_num-1:0] rcount,
    input  replica_data_t       out_data_i,
    output logic                out_valid_o,
    output replica_data_t       out_data_o
);

logic [6:0]   K, L;
assign K = opt.K;
assign L = opt.L;

logic                out_valid_r;

assign out_valid_o = out_valid_r;
//assign out_data_o  = out_data_i;

logic                set_p;
logic                use_p;
logic [city_num-1:0] p;
logic [7:0][2:0]     sel;
logic [7:0]          hold;
always_ff @(posedge clk) begin
    set_p <= '0;
    use_p <= '0;
    if (command == NOP && rcount == 0) begin
        for(int i = 0; i < 8; i += 1)                begin sel[i] <= i;      hold[i] <= '0; end
    end else if (opt.command == THR) begin
        for(int i = 0; i < 8; i += 1)                begin sel[i] <= i;      hold[i] <= '0; end
    end else if (opt.command == OR0) begin
        if (rcount < K/8) begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '0; end
        end else if (rcount == K/8) begin
            set_p <= '1;
            if (rcount == L/8) begin
                use_p <= '1;
                for(int i = 0;     i < K%8; i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
                for(int i = K%8;   i < L%8; i += 1)  begin sel[i] <= i+1;    hold[i] <= '1; end
                                                     begin sel[L%8] <= K%8;  hold[L%8] <= '1; end
                for(int i = L%8+1; i < 8;   i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
            end else begin
                for(int i = 0;     i < K%8; i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
                for(int i = K%8;   i < 8;   i += 1)  begin sel[i] <= i+1;    hold[i] <= (i != 7); end
            end    
        end else if (rcount < L/8) begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i+1;    hold[i] <= (i != 7); end
        end else if (rcount == L/8) begin
            use_p <= '1;
            for(int i = 0;     i < L%8; i += 1)      begin sel[i] <= i+1;    hold[i] <= '1; end
                                                     begin sel[L%8] <= 0;    hold[L%8] <= '1; end
            for(int i = L%8+1; i < 8;   i += 1)      begin sel[i] <= i;      hold[i] <= '1; end
        end else begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '1; end
        end
    end
end    

logic [7:0]          hold_d1;
replica_data_t       out_data_hold;
always_comb begin
    for(int i = 0; i < 7; i += 1) begin
        if(hold_d1[i])  out_data_o[i] = out_data_hold[i];
        else            out_data_o[i] = out_data_i[sel[i]];
    end
    if(hold_d1[7])            out_data_o[7] = out_data_hold[7];
    else if(hold_d1 == 8'h7f) out_data_o[7] = out_data_i[0];
    else                      out_data_o[7] = out_data_i[sel[7]];
end

always_ff @(posedge clk) begin
    if(set_p) p <= out_data_i[K%8];
    hold_d1 <= hold;
    for(int i = 0; i < 8; i += 1) begin
        if(~set_p & use_p & i == L%8) out_data_hold[i] <= p;
        else                          out_data_hold[i] <= out_data_i[sel[i]];
    end
end
    
always_ff @(posedge clk) begin
    if (reset) begin
        out_valid_r <= '0;
    end else if (command != NOP) begin
        out_valid_r <= ~((opt.command != THR) && (rcount == K/8));
    end else if (rcount != '0 || hold != 0) begin
        out_valid_r <= ~((opt.command != THR) && (rcount == K/8));
    end else begin
        out_valid_r <= '0;
    end
end    

always_ff @(posedge clk) begin
    if (reset)                        rcount <= '0;
    else if (command != NOP)          rcount <= rcount + 1;
    else if (rcount != '0)
        if (rcount + 1 != city_num)   rcount <= rcount + 1;
        else                          rcount <= '0;
end    

endmodule