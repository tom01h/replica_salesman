package replica_pkg;

//parameter city_num = 100;

parameter city_num = 30;
parameter city_num_log = $clog2(city_num);
parameter city_div = (city_num + 7) / 8;
parameter city_div_log = $clog2(city_div);
parameter dbeta = 5;

typedef enum logic [1:0] {
    NOP  = 2'b00,
    SELF = 2'b01,          // レプリカ交換なし
    PREV = 2'b10,          // 逆温度が小さいレプリカと交換
    FOLW = 2'b11           // 逆温度が大きいレプリカと交換
} exchange_command_t;

typedef enum logic [2:0] {
    KN = 3'b000,
    KP = 3'b001,
    KM = 3'b010,
    LN = 3'b100,
    LP = 3'b101,
    LM = 3'b110
} distance_select_t;

typedef enum logic [1:0] {
    DNOP = 2'b00,
    ZERO = 2'b01,
    PLS  = 2'b10,
    MNS  = 2'b11
} distance_op_t;

typedef struct packed {
    distance_select_t select;
    distance_op_t     op;
} distance_command_t;

typedef enum logic [1:0] { // K, L の対象関係は以下のみサポート
    THR = 2'b00,
    TWO = 2'b01,           // 2-opt  K < L
    OR0 = 2'b10,           // or-opt K < L
    OR1 = 2'b11            // or-opt K > L + 1
} opt_command_t;

typedef struct packed {
    opt_command_t command;
    logic [6:0]   K;
    logic [6:0]   L;
} opt_t;

typedef logic [7:0][6:0] replica_data_t;
typedef logic        [17:0] distance_data_t; // 1.17
typedef logic signed [20:0] delata_data_t;   // 3.17
typedef logic        [22:0] total_data_t;    // 6.17

endpackage : replica_pkg