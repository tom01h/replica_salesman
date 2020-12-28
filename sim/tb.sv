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
    end

    logic                      set_random;
    logic [63:0]               random_seed;
    logic                      opt_run;
    opt_command_t              opt_com;
    logic                      distance_write;
    logic [city_num_log*2-1:0] distance_w_addr;
    distance_data_t            distance_w_data;
    total_data_t               total_in_data;
    total_data_t               total_out_data;
    logic                      ordering_read;
    logic                      ordering_write;
    logic [7:0][7:0]           ordering_wdata;
    logic                      ordering_ready;
    logic                      ordering_out_valid;
    logic [7:0][7:0]           ordering_out_data;
    logic                      exchange_valid;
    logic                      shift_distance;

    task v_init();
        reset = 1'b1;
        repeat(10) @(negedge clk);
        opt_com = THR;
        set_random = 'b0;
        opt_run = 'b0;
        distance_write = 'b0;
        ordering_read = 'b0;
        ordering_write = 'b0;
        reset = 1'b0;
        exchange_valid = 1'b0;
        shift_distance = 'b0;
    endtask

    task v_finish();
        repeat(10) @(negedge clk);
        $finish;
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
        for(int i = 0; i < size/8; i++)begin
            do @(negedge clk); while(ordering_ready == 0);
            for(int j = 0; j < 8; j++)begin
                data[i*8+j] = ordering_out_data[7-j];
            end
        end
        do @(negedge clk); while(ordering_ready == 0);
        for(int j = 0; j < size%8; j++)begin
            data[size/8*8+j] = ordering_out_data[7-j];
        end
        ordering_read = 'b0;
    endtask

    task v_set_distance (input int data[ncity*ncity], input int size);
        distance_w_addr = 'b0;

        distance_write = 'b1;
        for(int i=1; i<size; i++)begin
            for(int j=0; j<i; j++)begin
                distance_w_data = data[i*size + j];
                repeat(1) @(negedge clk);
                distance_w_addr += 1;
            end
        end
        distance_write = 'b0;
        
    endtask;
        
    task v_set_total (input int data[nbeta], input int size);
        shift_distance = 'b1;
        for(int i = 0; i < size; i++)begin
            total_in_data = data[i];
            repeat(1) @(negedge clk);
        end
        shift_distance = 'b0;
    endtask

    task v_get_total (output int data[nbeta], input int size);
        shift_distance = 'b1;
        for(int i = 0; i < size; i++)begin
            data[i] = total_out_data;
            repeat(1) @(negedge clk);
        end
        shift_distance = 'b0;
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
        exchange_valid = 'b1;
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
        exchange_valid = 'b0;
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
        .set_random          ( set_random         ),
        .random_seed         ( random_seed        ),
        .opt_run             ( opt_run            ),
        .shift_distance      ( shift_distance     ),
        .opt_com             ( opt_com            ),
        .exchange_valid      ( exchange_valid     ),
        .distance_write      ( distance_write     ),
        .distance_w_addr     ( distance_w_addr    ),
        .distance_w_data     ( distance_w_data    ),
        .total_in_data       ( total_in_data      ),
        .total_out_data      ( total_out_data     ),
        .ordering_read       ( ordering_read      ),
        .ordering_write      ( ordering_write     ),
        .ordering_wdata      ( ordering_wdata     ),
        .ordering_ready      ( ordering_ready     ),
        .ordering_out_valid  ( ordering_out_valid ),
        .ordering_out_data   ( ordering_out_data  )
    );
endmodule