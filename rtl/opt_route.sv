module opt_route
    import replica_pkg::*;
(
    input  logic                clk,
    input  logic                reset,
    input  replica_command_t    command,
    input  logic                command_nop_d,
    input  opt_t                opt,
    input  opt_t                opt_d,
    output logic [city_num-1:0] rcount,
    input  replica_data_t       out_data_i,
    output logic                out_valid_o,
    output replica_data_t       out_data_o
);

logic [6:0]   K, L;
assign K = opt_d.K;
assign L = opt_d.L;

logic                out_valid_r;
logic [city_num-1:0] dcount;

assign out_valid_o = out_valid_r;
//assign out_data_o  = out_data_i;

logic                set_p;
logic                use_p;
logic [7:0]          p;
logic [7:0][2:0]     sel;
logic [7:0]          hold;
logic                or1_ini;
always_ff @(posedge clk) begin
    set_p <= '0;
    use_p <= '0;
    if (command_nop_d && dcount == 0 && ~or1_ini && ~(set_p & opt_d.command == OR1)) begin
        for(int i = 0; i < 8; i += 1)                begin sel[i] <= i;      hold[i] <= '0; end
    end else if (opt_d.command == THR) begin
        for(int i = 0; i < 8; i += 1)                begin sel[i] <= i;      hold[i] <= '0; end
    end else if (opt_d.command == OR0) begin
        if (dcount < K/8) begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '0; end
        end else if (dcount == K/8) begin
            set_p <= '1;
            if (dcount == L/8) begin
                use_p <= '1;
                for(int i = 0;     i < K%8; i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
                for(int i = K%8;   i < L%8; i += 1)  begin sel[i] <= i+1;    hold[i] <= '1; end
                                                     begin sel[L%8] <= K%8;  hold[L%8] <= '1; end
                for(int i = L%8+1; i < 8;   i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
            end else begin
                for(int i = 0;     i < K%8; i += 1)  begin sel[i] <= i;      hold[i] <= '1; end
                for(int i = K%8;   i < 8;   i += 1)  begin sel[i] <= i+1;    hold[i] <= (i != 7); end
            end    
        end else if (dcount < L/8) begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i+1;    hold[i] <= (i != 7); end
        end else if (dcount == L/8) begin
            use_p <= '1;
            for(int i = 0;     i < L%8; i += 1)      begin sel[i] <= i+1;    hold[i] <= '1; end
                                                     begin sel[L%8] <= 0;    hold[L%8] <= '1; end
            for(int i = L%8+1; i < 8;   i += 1)      begin sel[i] <= i;      hold[i] <= '1; end
        end else begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '1; end
        end
    end else if (opt_d.command == OR1) begin
        if (~command_nop_d) begin
        end else if (or1_ini) begin
            set_p <= '1;
        end else if (dcount < L/8) begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '0; end
        end else if (dcount == L/8) begin
            use_p <= '1;
            if (dcount == K/8) begin
                for(int i = 0;     i < L%8+1; i += 1)begin sel[i] <= i;      hold[i] <= '0; end
                for(int i = L%8+1; i < K%8+1; i += 1)begin sel[i] <= i-1;    hold[i] <= '0; end
                for(int i = K%8+1; i < 8;     i += 1)begin sel[i] <= i;      hold[i] <= '0; end
            end else begin
                                                     begin sel[0] <= 0;      hold[0] <= '1; end
                for(int i = 1;     i < L%8; i += 1)  begin sel[i] <= i;      hold[i] <= '0; end
                if(L%8 != 0)                         begin sel[L%8] <= 0;    hold[L%8] <= '0; end
                for(int i = L%8+1; i < 8;   i += 1)  begin sel[i] <= i-1;    hold[i] <= '0; end
            end
        end else if (dcount < K/8) begin
                                                     begin sel[0] <= 7;      hold[0] <= '1; end
            for(int i = 1; i < 8; i += 1)            begin sel[i] <= i-1;    hold[i] <= '0; end
        end else if (dcount == K/8) begin
            for(int i = 0;     i < K%8+1; i += 1)    begin sel[i] <= i-1;    hold[i] <= '0; end
            for(int i = K%8+1; i < 8;     i += 1)    begin sel[i] <= i;      hold[i] <= '0; end
        end else begin
            for(int i = 0; i < 8; i += 1)            begin sel[i] <= i;      hold[i] <= '0; end
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
    if((dcount == L/8) && (opt_d.command == OR1)) hold_d1[L%8] <= '1;
    for(int i = 0; i < 8; i += 1) begin
        if (opt_d.command == OR0)
            if(~set_p & use_p & i == L%8) out_data_hold[i] <= p;
            else                          out_data_hold[i] <= out_data_i[sel[i]];
        else if (opt_d.command == OR1)
            if(set_p)                     out_data_hold[i] <= out_data_i[K%8];
            else if(hold[0])              out_data_hold[i] <= out_data_i[7];
    end
end
    
always_ff @(posedge clk) begin
    if (reset) begin
        out_valid_r <= '0;
    end else if (~command_nop_d) begin
        out_valid_r <= ~((opt_d.command == OR0) && (dcount == K/8) || or1_ini);
    end else if (dcount != '0 || hold != 0 || set_p) begin
        out_valid_r <= ~((opt_d.command == OR0) && (dcount == K/8) || or1_ini);
    end else begin
        out_valid_r <= '0;
    end
end    

always_ff @(posedge clk) begin
    if (reset)                 begin  rcount <= '0;           or1_ini <= '0; end
    else if (command != NOP)
        if(opt.command == OR1) begin  rcount <= opt.K/8;      or1_ini <= '1; end
        else                          rcount <= rcount + 1;
    else if (or1_ini && rcount != 0)  rcount <= '0;
    else if (or1_ini)         begin   rcount <= rcount + 1;   or1_ini <= '0; end
    else if (rcount != '0)
        if (rcount + 1 != city_num)   rcount <= rcount + 1;
        else                          rcount <= '0;

    if (reset)                        dcount <= '0;
    else                              dcount <= rcount;
end    

endmodule