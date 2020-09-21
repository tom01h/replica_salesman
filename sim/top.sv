module top
    import replica_pkg::*;
(
    input  logic             clk,
    input  logic             reset,
    input  replica_command_t command,
    input  logic             set_opt,
    input  opt_command       opt_com,
    input  logic [6:0]       K,
    input  logic [6:0]       L,
    input  logic             ordering_in_valid,
    input  logic [7:0][7:0]  ordering_in_data,
    output logic             ordering_out_valid,
    output logic [7:0][7:0]  ordering_out_data

);

logic             rbank;
replica_command_t command_d1;
logic             in_valid_d1,   in_valid_d2,   in_valid_d3;
replica_data_t    in_data_d1,    in_data_d2,    in_data_d3;

always_ff @(posedge clk)begin
    if(reset)begin
        rbank <= '0;
        command_d1 <= '0;
    end else begin    
        if(command != 0)begin
            rbank <= ~rbank;
        end
        command_d1 <= command;
        in_valid_d1 <= ordering_in_valid;
        for(int i=0; i<8; i++) in_data_d1[i][6:0] <= ordering_in_data[7-i][6:0];
        in_valid_d2 <= in_valid_d1;
        in_data_d2 <= in_data_d1;
        in_valid_d3 <= in_valid_d2;
        in_data_d3 <= in_data_d2;
    end
end

opt_t  [31:0] opt;
integer opt_count;
logic opt_run;
always_ff @(posedge clk)begin
    if(set_opt)begin
        opt[opt_count].command <= opt_com;
        opt[opt_count].K       <= K;
        opt[opt_count].L       <= L;
        opt_count              <= opt_count + 1;
        opt_run                <= 1;
    end else if(command!=0)begin
        opt_count              <= 0;
    end else if(opt_run)begin
        opt_count              <= opt_count + 1;
        if(opt_count == 5)begin
            opt_run            <= '0;
            opt_count          <= 0;
            for(int i=0; i<32; i++)begin
                opt[i].command <= 0;
            end
        end
    end
end

logic             [33:0]  ordering_valid;
replica_data_t    [33:0]  ordering_data;

assign ordering_valid[0] = in_valid_d3;
assign ordering_data[0]  = in_data_d3;

always_comb
    for(int i=0; i<8; i++) ordering_out_data[i][6:0] = ordering_data[32][7-i][6:0];

for (genvar g = 0; g < 32; g += 1) begin
    replica_ram replica_ram
    (
        .clk         ( clk                 ),
        .reset       ( reset               ),
        .command     ( command_d1          ),
        .opt         ( opt[g]              ),
        .rbank       ( rbank               ),
        .prev_valid  ( ordering_valid[g]   ),
        .prev_data   ( ordering_data[g]    ),
        .folw_valid  ( ordering_valid[g+2] ),
        .folw_data   ( ordering_data[g+2]  ),
        .out_valid   ( ordering_valid[g+1] ),
        .out_data    ( ordering_data[g+1]  )
    );
end

endmodule