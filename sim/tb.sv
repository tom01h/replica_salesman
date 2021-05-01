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

    total_data_t               distance_rdata;
    logic                      ordering_read;
    logic                      ordering_ready;
    logic [7:0][7:0]           ordering_rdata;
    logic                      distance_shift;

    task v_init();
        reset = 'b1;
        repeat(10) @(negedge clk);
        ordering_read = 'b0;
        distance_shift = 'b0;
        reset = 'b0;
    endtask

    task v_finish();
        repeat(10) @(negedge clk);
        //$finish;
    endtask

    task v_get_ordering (output int data[ncity], input int size);
        ordering_read = 'b1;
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

    task v_get_total (output int data[nbeta], input int size);
        distance_shift = 'b1;
        for(int i = 0; i < size; i++)begin
            data[i] = distance_rdata;
            repeat(1) @(negedge clk);
        end
        distance_shift = 'b0;
    endtask

    logic [31:0]               S_AXI_AWADDR;
    logic                      S_AXI_AWVALID;
    logic                      S_AXI_AWREADY;
    logic [63:0]               S_AXI_WDATA;
    logic [7:0]                S_AXI_WSTRB;
    logic                      S_AXI_WVALID;
    logic                      S_AXI_WREADY;
    logic [1:0]                S_AXI_BRESP;
    logic                      S_AXI_BVALID;
    logic                      S_AXI_BREADY;

    logic [31:0]               S_AXI_ARADDR;
    logic                      S_AXI_ARVALID;
    logic                      S_AXI_ARREADY;
    logic [63:0]               S_AXI_RDATA;
    logic [1:0]                S_AXI_RRESP;
    logic                      S_AXI_RVALID;
    logic                      S_AXI_RREADY;

    initial begin
        S_AXI_BREADY = 'b1;
        S_AXI_AWVALID = 'b0;
        S_AXI_WSTRB = '1;
        S_AXI_WVALID = 'b0;
        S_AXI_ARVALID = 'b0;
        S_AXI_RREADY = 'b1;
    end

    task v_write64 (input int address, input longint unsigned data);
        S_AXI_AWADDR = address;
        S_AXI_AWVALID = 'b1;
        S_AXI_WDATA = data;
        S_AXI_WVALID = 'b1;
        repeat(1) @(negedge clk);
        S_AXI_AWVALID = 'b0;
        S_AXI_WVALID = 'b0;
        repeat(1) @(negedge clk);
    endtask

    task v_read64 (input int address, output longint unsigned data);
        S_AXI_ARADDR = address;
        S_AXI_ARVALID = 'b1;
        repeat(1) @(negedge clk);
        S_AXI_ARVALID = 'b0;
        data = S_AXI_RDATA;
    endtask

    task v_wait (input int times);
        repeat(times) @(negedge clk);
    endtask

    export "DPI-C" task v_init;
    export "DPI-C" task v_finish;
    export "DPI-C" task v_get_ordering;
    export "DPI-C" task v_get_total;
    export "DPI-C" task v_write64;
    export "DPI-C" task v_read64;
    export "DPI-C" task v_wait;

    import "DPI-C" context task c_tb();

    top top
    (
        .clk                 ( clk                ),
        .reset               ( reset              ),

        .S_AXI_AWADDR        ( S_AXI_AWADDR       ),
        .S_AXI_AWVALID       ( S_AXI_AWVALID      ),
        .S_AXI_AWREADY       ( S_AXI_AWREADY      ),
        .S_AXI_WDATA         ( S_AXI_WDATA        ),
        .S_AXI_WSTRB         ( S_AXI_WSTRB        ),
        .S_AXI_WVALID        ( S_AXI_WVALID       ),
        .S_AXI_WREADY        ( S_AXI_WREADY       ),
        .S_AXI_BRESP         ( S_AXI_BRESP        ),
        .S_AXI_BVALID        ( S_AXI_BVALID       ),
        .S_AXI_BREADY        ( S_AXI_BREADY       ),

        .S_AXI_ARADDR        ( S_AXI_ARADDR       ),
        .S_AXI_ARVALID       ( S_AXI_ARVALID      ),
        .S_AXI_ARREADY       ( S_AXI_ARREADY      ),
        .S_AXI_RDATA         ( S_AXI_RDATA        ),
        .S_AXI_RRESP         ( S_AXI_RRESP        ),
        .S_AXI_RVALID        ( S_AXI_RVALID       ),
        .S_AXI_RREADY        ( S_AXI_RREADY       ),

        .distance_shift      ( distance_shift     ),
        .distance_rdata      ( distance_rdata     ),

        .ordering_read       ( ordering_read      ),
        .ordering_rdata      ( ordering_rdata     ),
        .ordering_ready      ( ordering_ready     )
    );
endmodule