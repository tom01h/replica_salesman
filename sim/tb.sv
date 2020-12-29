module tb;
    import replica_pkg::*;

    parameter nbeta=32;
    parameter dbeta=5;
    parameter ncity=30+1;
    parameter replica_num = 32;

    logic  clk;
    logic  reset;

    always begin
        #5 clk = 'b0;
        #5 clk = 'b1;
    end

    initial begin
        clk = 1'b1;
        c_tb();
        repeat(10) @(negedge clk);
        $finish;
    end

    logic                      set_random;
    logic [63:0]               random_seed;
    logic                      opt_run;
    opt_command_t              opt_com;
    logic                      tp_dis_write;
    logic [city_num_log*2-1:0] tp_dis_waddr;
    distance_data_t            tp_dis_wdata;
    total_data_t               distance_wdata;
    total_data_t               distance_rdata;
    logic                      ordering_read;
    logic                      ordering_write;
    logic [7:0][7:0]           ordering_wdata;
    logic                      ordering_ready;
    logic [7:0][7:0]           ordering_rdata;
    logic                      distance_shift;

    task v_init();
        reset = 'b1;
        repeat(10) @(negedge clk);
        opt_com = THR;
        set_random = 'b0;
        opt_run = 'b0;
        tp_dis_write = 'b0;
        ordering_read = 'b0;
        ordering_write = 'b0;
        distance_shift = 'b0;
        reset = 'b0;
    endtask

    task v_finish();
        repeat(10) @(negedge clk);
        //$finish;
    endtask

    task v_set_ordering (input int data[ncity], input int size);
        ordering_write = 'b1;
        for(int i = 0; i < size/8; i++)begin
            for(int j = 0; j < 8; j++)begin
                ordering_wdata[7-j] = data[i*8+j];
            end
            do @(negedge clk); while(ordering_ready == 0);
        end
        for(int j = 0; j < 8; j++)begin
            if(j < size%8) ordering_wdata[7-j] = data[size/8*8+j];
            else           ordering_wdata[7-j] = 'b0;
        end
        do @(negedge clk); while(ordering_ready == 0);
        ordering_write = 'b0;
    endtask;

    task v_get_ordering (output int data[ncity], input int size);
        ordering_read = 'b1;
        opt_com = THR;
        for(int i = 0; i < size/8; i++)begin
            do @(negedge clk); while(ordering_ready == 0);
            for(int j = 0; j < 8; j++)begin
                data[i*8+j] = ordering_rdata[7-j];
            end
            // ordering_read = 'b0; @(negedge clk); ordering_read = 'b1;
        end
        do @(negedge clk); while(ordering_ready == 0);
        for(int j = 0; j < size%8; j++)begin
            data[size/8*8+j] = ordering_rdata[7-j];
        end
        ordering_read = 'b0;
    endtask

    task v_set_distance (input int data[ncity*ncity], input int size);
        tp_dis_waddr = 'b0;

        tp_dis_write = 'b1;
        for(int i=1; i<size; i++)begin
            for(int j=0; j<i; j++)begin
                tp_dis_wdata = data[i*size + j];
                repeat(1) @(negedge clk);
                tp_dis_waddr += 1;
            end
        end
        tp_dis_write = 'b0;
        
    endtask;
        
    task v_set_total (input int data[nbeta], input int size);
        distance_shift = 'b1;
        for(int i = 0; i < size; i++)begin
            distance_wdata = data[i];
            repeat(1) @(negedge clk);
        end
        distance_shift = 'b0;
    endtask

    task v_get_total (output int data[nbeta], input int size);
        distance_shift = 'b1;
        opt_com = THR;
        for(int i = 0; i < size; i++)begin
            data[i] = distance_rdata;
            repeat(1) @(negedge clk);
        end
        distance_shift = 'b0;
    endtask

    task v_set_random (input longint unsigned seed[nbeta]);
        repeat(1) @(negedge clk);
        set_random = 'b1;
        repeat(1) @(negedge clk);
        set_random = 'b0;
        for(int i = 0; i < nbeta; i++)begin
            random_seed = seed[i];
            repeat(1) @(negedge clk);
        end
        repeat(1) @(negedge clk);
    endtask

    task v_run (input int command);
        repeat(1) @(negedge clk);
        opt_run = 'b1;
        opt_com = opt_command_t'(command);
        repeat(1) @(negedge clk);
        opt_run = 'b0;
        repeat(20) @(negedge clk);  // random
        repeat(20) @(negedge clk);  // delta distance
        repeat(20) @(negedge clk);  // metropolis test
        repeat(20) @(negedge clk);  // exchange test
        repeat(20) @(negedge clk);  // replica exchange
    endtask

    export "DPI-C" task v_init;
    export "DPI-C" task v_finish;
    export "DPI-C" task v_set_ordering;
    export "DPI-C" task v_get_ordering;
    export "DPI-C" task v_set_distance;
    export "DPI-C" task v_set_total;
    export "DPI-C" task v_get_total;
    export "DPI-C" task v_set_random;
    export "DPI-C" task v_run;

    import "DPI-C" context task c_tb();

    top top
    (
        .clk                 ( clk                ),
        .reset               ( reset              ),

        .opt_run             ( opt_run            ),
        .opt_com             ( opt_com            ),

        .set_random          ( set_random         ),
        .random_seed         ( random_seed        ),

        .tp_dis_write        ( tp_dis_write       ),
        .tp_dis_waddr        ( tp_dis_waddr       ),
        .tp_dis_wdata        ( tp_dis_wdata       ),
        
        .distance_shift      ( distance_shift     ),
        .distance_wdata      ( distance_wdata     ),
        .distance_rdata      ( distance_rdata     ),

        .ordering_read       ( ordering_read      ),
        .ordering_rdata      ( ordering_rdata     ),
        .ordering_write      ( ordering_write     ),
        .ordering_wdata      ( ordering_wdata     ),
        .ordering_ready      ( ordering_ready     )
    );
endmodule