package replica_pkg;

typedef enum logic [1:0] {
    NOP  = 2'b00,
    SELF = 2'b01,          // レプリカ交換なし
    PREV = 2'b10,          // 逆温度が小さいレプリカと交換
    FOLW = 2'b11           // 逆温度が大きいレプリカと交換
} replica_command_t;

typedef enum logic [1:0] { // K, L の対象関係は以下のみサポート
    THR = 2'b00,
    TWO = 2'b01,           // 2-opt  K < L
    OR0 = 2'b10,           // or-opt K < L
    OR1 = 2'b11            // or-opt K > L + 1
} opt_command;

typedef struct packed {
    opt_command command;
    logic [6:0] K;
    logic [6:0] L;
} opt_t;

typedef logic [7:0][6:0] replica_data_t;

//parameter city_num = 13;     // 100 <= 8*13
//parameter replica_num = 200;
parameter city_num = 4;     // 30 <= 8*4
//parameter replica_num = 32;
parameter replica_num = 4;

endpackage : replica_pkg