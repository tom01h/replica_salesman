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
    logic                      random_run;
    logic                      run_command;
    logic                      set_command;
    logic                      run_distance;
    exchange_command_t         c_exchange;
    exchange_command_t         c_metropolis;
    opt_command_t              opt_com;
    logic                      distance_write;
    logic [city_num_log*2-1:0] distance_w_addr;
    distance_data_t            distance_w_data;
    total_data_t               total_in_data;
    total_data_t               total_out_data;
    logic                      ordering_in_valid;
    logic [7:0][7:0]           ordering_in_data;
    logic                      ordering_out_valid;
    logic [7:0][7:0]           ordering_out_data;
    logic                      exchange_valid;

    task v_init();
        reset = 1'b1;
        repeat(10) @(negedge clk);
        set_random = 'b0;
        random_run = 'b0;
        run_command = 'b0;
        set_command = 'b0;
        run_distance = 'b0;
        distance_write = 'b0;
        ordering_in_valid = 'b0;
        reset = 1'b0;
        exchange_valid = 1'b0;
    endtask

    task v_finish();
        repeat(10) @(negedge clk);
        $finish;
    endtask

    task v_set_ordering (input int data[ncity], input int size);
        run_command = 1;
        c_exchange = PREV;
        repeat(1) @(negedge clk);
        run_command = 0;
        
        ordering_in_valid = 1;
        for(int i = 0; i < size/8; i++)begin
            for(int j = 0; j < 8; j++)begin
                ordering_in_data[7-j] = data[i*8+j];
            end
            repeat(1) @(negedge clk);
        end
        for(int j = 0; j < 8; j++)begin
            ordering_in_data[j] = 'b0;
        end
        for(int j = 0; j < size%8; j++)begin
            ordering_in_data[7-j] = data[size/8*8+j];
        end
        repeat(1) @(negedge clk);
        ordering_in_valid = 0;

    endtask;

    task v_get_ordering (output int data[ncity], input int size);
        run_command = 'b1;
        c_exchange = PREV;
        repeat(1) @(negedge clk);
        run_command = 'b0;
        repeat(2) @(negedge clk);
        for(int i = 0; i < size/8; i++)begin
            repeat(1) @(negedge clk);
            for(int j = 0; j < 8; j++)begin
                data[i*8+j] = ordering_out_data[7-j];
            end
        end
        repeat(1) @(negedge clk);
        for(int j = 0; j < size%8; j++)begin
            data[size/8*8+j] = ordering_out_data[7-j];
        end
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
        c_metropolis = PREV;
        for(int i = 0; i < size; i++)begin
            total_in_data = data[i];
            repeat(1) @(negedge clk);
        end
        c_metropolis = NOP;
    endtask

    task v_get_total (output int data[nbeta], input int size);
        c_metropolis = PREV;
        for(int i = 0; i < size; i++)begin
            data[i] = total_out_data;
            repeat(1) @(negedge clk);
        end
    endtask

    task v_metropolis_test (input int command);
        run_distance = 'b1;
        exchange_valid = 'b1;
        opt_com = opt_command_t'(command);
        repeat(1) @(negedge clk);
        run_distance = 'b0;
        repeat(20) @(negedge clk);
        c_metropolis = SELF;
        repeat(1) @(negedge clk);
        c_metropolis = NOP;
    endtask

    task v_set_command (input int command);
        set_command = 'b1;
        c_exchange = exchange_command_t'(command);
        repeat(1) @(negedge clk);
        set_command = 'b0;
    endtask

    task v_run_opt (input int command);
        repeat(1) @(negedge clk);
        run_command = 'b1;
        c_exchange = exchange_command_t'(command);
        repeat(1) @(negedge clk);
        run_command = 'b0;
        c_metropolis = FOLW;
        repeat(1) @(negedge clk);
        c_metropolis = NOP;
        repeat(15) @(negedge clk);
        exchange_valid = 'b0;
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

    task v_run_random (input int command);
        repeat(1) @(negedge clk);
        random_run = 'b1;
        opt_com = opt_command_t'(command);
        repeat(1) @(negedge clk);
        random_run = 'b0;
        repeat(20) @(negedge clk);
    endtask

    export "DPI-C" task v_init;
    export "DPI-C" task v_finish;
    export "DPI-C" task v_set_ordering;
    export "DPI-C" task v_get_ordering;
    export "DPI-C" task v_set_distance;
    export "DPI-C" task v_set_total;
    export "DPI-C" task v_get_total;
    export "DPI-C" task v_metropolis_test;
    export "DPI-C" task v_set_command;
    export "DPI-C" task v_run_opt;
    export "DPI-C" task v_set_random;
    export "DPI-C" task v_run_random;

    import "DPI-C" context task c_tb();

    top top
    (
        .clk                 ( clk                ),
        .reset               ( reset              ),
        .set_random          ( set_random         ),
        .random_seed         ( random_seed        ),
        .random_run          ( random_run         ),
        .run_command         ( run_command        ),
        .set_command         ( set_command        ),
        .run_distance        ( run_distance       ),
        .c_exchange          ( c_exchange         ),
        .c_metropolis        ( c_metropolis       ),
        .opt_com             ( opt_com            ),
        .exchange_valid      ( exchange_valid     ),
        .distance_write      ( distance_write     ),
        .distance_w_addr     ( distance_w_addr    ),
        .distance_w_data     ( distance_w_data    ),
        .total_in_data       ( total_in_data      ),
        .total_out_data      ( total_out_data     ),
        .ordering_in_valid   ( ordering_in_valid  ),
        .ordering_in_data    ( ordering_in_data   ),
        .ordering_out_valid  ( ordering_out_valid ),
        .ordering_out_data   ( ordering_out_data  )
    );
endmodule