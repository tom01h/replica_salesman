package replica_pkg;

typedef enum logic [1:0] {
    NOP  = 2'b00,
    PREV = 2'b10,
    FOLW = 2'b11
} replica_command;

typedef logic [7:0][6:0] replica_data;

//parameter city_num = 13;     // 100 <= 8*13
//parameter replica_num = 32;
parameter city_num = 4;     // 30 <= 8*4
parameter replica_num = 4;

endpackage : replica_pkg