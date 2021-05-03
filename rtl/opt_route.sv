module opt_route
    import replica_pkg::*;
(
    input  logic                    clk,
    input  logic                    reset,
    input  exchange_command_t       command,
    input  logic                    command_nop_d,
    input  opt_t                    opt,
    input  opt_t                    opt_d,
    output logic [city_div_log-1:0] rcount,
    input  replica_data_t           out_data_i,
    output logic                    out_valid_o,
    output replica_data_t           out_data_o
);

logic [6:0]   K, L;
logic [2:0]   K8, L8;
assign K = opt_d.K;
assign L = opt_d.L;
assign K8 = K % 8;
assign L8 = (opt_d.command == OR0)? L % 8 :
            (opt_d.command == OR1)? (L+1) % 8 :
            (opt_d.command == TWO)? (L-1) % 8 : L % 8 ;

logic                    out_valid_r;
logic [city_div_log-1:0] dcount;

assign out_valid_o = out_valid_r;

logic                set_p;
logic                use_p;
logic                rev;
logic                rev_d;
logic [7:0]          p;
logic [7:0][2:0]     sel;
logic [7:0]          hold;
logic                or1_ini;
always_ff @(posedge clk) begin
    set_p <= '0;
    use_p <= '0;
    for(int i = 0; i < 8; i += 1) begin
        if (command_nop_d && dcount == 0 && ~or1_ini && ~(set_p & opt_d.command == OR1) && ~(rev_d & opt_d.command == TWO)) begin
                                                  sel[i] <= i;    hold[i] <= '0;
        end else if (opt_d.command == THR) begin
                                                  sel[i] <= i;    hold[i] <= '0;
        end else if (opt_d.command == OR0) begin
            if (dcount < K/8) begin
                                                  sel[i] <= i;    hold[i] <= '0;
            end else if (dcount == K/8) begin
                set_p <= '1;
                if (dcount == L/8) begin
                    use_p <= '1;
                    if(i < K8)              begin sel[i] <= i;    hold[i] <= '1; end
                    if(K8 <= i && i < L8)   begin sel[i] <= i+1;  hold[i] <= '1; end
                    if(i == L8)             begin sel[i] <= K8;   hold[i] <= '1; end
                    if(L8+1 <= i)           begin sel[i] <= i;    hold[i] <= '1; end
                end else begin
                    if(i < K8)              begin sel[i] <= i;    hold[i] <= '1; end
                    if(K8 <= i)             begin sel[i] <= i+1;  hold[i] <= (i != 7); end
                end
            end else if (dcount < L/8) begin
                                                  sel[i] <= i+1;  hold[i] <= (i != 7);
            end else if (dcount == L/8) begin
                use_p <= '1;
                if(i < L8)                  begin sel[i] <= i+1;  hold[i] <= '1; end
                if(i == L8)                 begin sel[i] <= 0;    hold[i] <= '1; end
                if(L8+1 <= i)               begin sel[i] <= i;    hold[i] <= '1; end
            end else begin
                                                  sel[i] <= i;    hold[i] <= '1;
            end
        end else if (opt_d.command == OR1) begin
            if (~command_nop_d) begin
            end else if (or1_ini) begin
                set_p <= '1;
            end else if (dcount < (L+1)/8) begin
                                                  sel[i] <= i;    hold[i] <= '0;
            end else if (dcount == (L+1)/8) begin
                use_p <= '1;
                if (dcount == K/8) begin
                    if(i < L8)              begin sel[i] <= i;    hold[i] <= '0; end
                    if(L8 <= i && i < K8+1) begin sel[i] <= i-1;  hold[i] <= '0; end
                    if(K8+1 <= i)           begin sel[i] <= i;    hold[i] <= '0; end
                end else begin
                    if(i == 0)              begin sel[i] <= i;    hold[i] <= '1; end
                    if(1 <= i && i < L8)    begin sel[i] <= i;    hold[i] <= '0; end
                    if(i == L8 && L8 != 0)  begin sel[i] <= 0;    hold[i] <= '0; end
                    if(L8+1 <= i)           begin sel[i] <= i-1;  hold[i] <= '0; end
                end
            end else if (dcount < K/8) begin
                if(i == 0)                  begin sel[i] <= 7;    hold[i] <= '1; end
                if(1 <= i)                  begin sel[i] <= i-1;  hold[i] <= '0; end
            end else if (dcount == K/8) begin
                if(i < K8+1)                begin sel[i] <= i-1;  hold[i] <= '0; end
                if(K8+1 <= i)               begin sel[i] <= i;    hold[i] <= '0; end
            end else begin
                                                  sel[i] <= i;    hold[i] <= '0;
            end
        end else if (opt_d.command == TWO) begin
            if (dcount < K/8) begin
                                                  sel[i] <= i;    hold[i] <= '0;
            end else if (dcount == K/8) begin
                if (dcount == (L-1)/8) begin
                    if(i < K8)              begin sel[i] <= i;    hold[i] <= '0; end
                    if(K8 <= i && i <=L8)   begin sel[i] <= K8 + L8 - i;  hold[i] <= '0; end
                    if(L8+1 <= i)           begin sel[i] <= i;    hold[i] <= '0; end
                end else if (~rev_d) begin
                    if(i < K8)              begin sel[i] <= i;    hold[i] <= '1; end
                end else if (rev_d && K8 + L8 < 7) begin
                    if(i <= L8)             begin sel[(K8+L8-i)%8] <= i; hold[i] <= '1; end
                    if(L8+1 <= i)           begin sel[(K8+L8-i)%8] <= i; hold[i] <= '0; end
                end else if (rev_d && dcount == (L-1)/8 -1) begin                                   // 必要なさそう
                    if(i < K8+L8-7)             begin sel[(K8+L8-i)%8] <= i; hold[i] <= '0; end
                    if(K8+L8-7 <= i && i <= L8) begin sel[(K8+L8-i)%8] <= i; hold[i] <= '1; end
                    if(L8 < i)                  begin sel[(K8+L8-i)%8] <= i; hold[i] <= '0; end
                end else if (rev_d)  begin
                    if(i < K8+L8-7)              begin sel[(K8+L8-i)%8] <= i; hold[i] <= '0; end
                    if(K8+L8-7 <= i && i < L8+1) begin sel[(K8+L8-i)%8] <= i; hold[i] <= '1; end
                    if(L8+1 <= i)                begin sel[(K8+L8-i)%8] <= i; hold[i] <= '0; end
                end
            end else if (dcount == (L-1)/8 && K8 + L8 < 7 && rev_d) begin
                if(i <= L8)                      begin sel[(K8+L8-i)%8] <= i; hold[(K8+L8-i)%8] <= '1; end
                if(L8 < i)                                                    hold[(K8+L8-i)%8] <= '0;
            end else if (dcount == (L-1)/8                && rev_d) begin
                if (dcount == K/8 + 1)begin
                    if(K8+L8-7 <= i)                   sel[(K8+L8-i)%8] <= i; hold[i] <= (L8 <= i && i < K8+L8-7);
                end else begin
                                                       sel[(K8+L8-i)%8] <= i; hold[i] <= (i < K8+L8-7);
                end
            end else if (dcount < (L-1)/8) begin
                                                       sel[(K8+L8-i)%8] <= i;
                if(K8 + L8 < 7)                                               hold[i] <= (i <= K8 + L8);
                else                                                          hold[i] <= (i < K8+L8-7);
            end else if (dcount == (L-1)/8) begin
                                                                              hold[i] <= '0;
                if(dcount == K/8 + 1 && K8 + L8 >= 7 && i < K8+L8-7) sel[(K8+L8-i)%8] <= i;
                else                                                 sel[i] <= i;
            end else begin
                                                       sel[i] <= i;           hold[i] <= '0;
            end
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
    if(hold_d1[7])                 out_data_o[7] = out_data_hold[7];
    else if (opt_d.command == TWO) out_data_o[7] = out_data_i[sel[7]];
    else if(hold_d1 == 8'h7f)      out_data_o[7] = out_data_i[0];
    else                           out_data_o[7] = out_data_i[sel[7]];
end

always_ff @(posedge clk) begin
    if(set_p) p <= out_data_i[K8];
    hold_d1 <= hold[7:0];
    if(command == NOP) begin
        if((dcount == (L+1)/8) && (opt_d.command == OR1)) hold_d1[L8] <= '1;
        if(                        rev_d && K8 + L8 <  7 && (opt_d.command == TWO)) hold_d1 <= hold_d1 | hold;
        if((dcount == (L-1)/8) && ~rev_d && K8 + L8 >= 7 && (opt_d.command == TWO)) hold_d1 <= hold_d1 | hold;
    end        
    for(int i = 0; i < 8; i += 1) begin
        if (opt_d.command == OR0) begin
            if(~set_p & use_p & i == L8)  out_data_hold[i] <= p;
            else                          out_data_hold[i] <= out_data_i[sel[i]];
        end else if (opt_d.command == OR1) begin
            if(set_p)                     out_data_hold[i] <= out_data_i[K8];
            else if(hold[0])              out_data_hold[i] <= out_data_i[7];
        end else if (opt_d.command == TWO) begin
            if(hold[i])                   out_data_hold[i] <= out_data_i[sel[i]];
        end
    end
end
    
always_ff @(posedge clk) begin
    if (reset) begin
        out_valid_r <= '0;
    end else if (hold != 0) begin
        out_valid_r <= ~(   (opt_d.command == TWO) && rev_d && (dcount == (L-1)/8) && L8 + K8 < 7 ||
                            (opt_d.command == TWO) && rev_d && (dcount == K/8)     && L8 + K8 >= 7   );
    end else if (~command_nop_d || dcount != '0 || set_p) begin
        out_valid_r <= ~(   (opt_d.command == OR0) && (dcount == K/8) ||
                            or1_ini ||
                            (opt_d.command == TWO) && (dcount == K/8) && (dcount != (L-1)/8) ||
                            (opt_d.command == TWO) && rev_d && (dcount == (L-1)/8) && L8 + K8 < 7 );
    end else begin
        out_valid_r <= '0;
    end
end    

always_ff @(posedge clk) begin
    rev_d <= rev;
    if (reset)                       begin   rcount <= '0;           or1_ini <= '0; rev <= '0; end
    else if (command != NOP)
        if (opt.command == TWO && rcount == opt.K/8  && rcount != (opt.L-1)/8 && ~rev) begin
                                             rcount <= (opt.L-1)/8;                 rev <= '1; end
        else if(opt.command == OR1)  begin   rcount <= opt.K/8;      or1_ini <= '1; end
        else                                 rcount <= rcount + 1;
    else if (or1_ini && ~command_nop_d)      rcount <= '0;
    else if (or1_ini)                begin   rcount <= rcount + 1;   or1_ini <= '0; end
    else if (rcount != '0 || rev)
        if (opt.command == TWO && rcount == opt.K/8  && rcount != (opt.L-1)/8 && ~rev) begin
                                             rcount <= (opt.L-1)/8;                 rev <= '1; end
        else if (opt.command == TWO && rcount == opt.K/8 && rev)
                                     begin   rcount <= (opt.L-1)/8;                 rev <= '0; end
        else if (rev)                        rcount <= rcount - 1;
        else if (rcount + 1 != city_div)     rcount <= rcount + 1;
        else                                 rcount <= '0;

    if (reset) dcount <= '0;
    else       dcount <= rcount;
end    

endmodule