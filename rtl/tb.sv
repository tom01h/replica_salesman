`timescale 1ns/1ns
import replica_pkg::*;

module tb();

    logic           clk, reset;

    initial begin
        reset=1;#15
        reset=0;
    end
    
    always begin
        clk=1;#5;
        clk=0;#5;
    end

    sim_top sim_top
    (
        .clk         ( clk       ),
        .reset       ( reset     )
    );
endmodule
