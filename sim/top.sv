module top
    import replica_pkg::*;
(
    input  logic             clk,
    input  logic             reset,
    input  replica_command_t command,
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
    
    opt_t opt;
    assign opt.command = opt_com;
    assign opt.K = K;
    assign opt.L = L;

logic             [33:0]  ordering_valid;
replica_data_t    [33:0]  ordering_data;

 assign ordering_valid[0] = in_valid_d3;
 assign ordering_data[0]  = in_data_d3;

for (genvar g = 0; g < 32; g += 1) begin
    replica_ram replica_ram
    (
        .clk         ( clk                 ),
        .reset       ( reset               ),
        .command     ( command_d1          ),
        .opt         ( opt                 ),
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