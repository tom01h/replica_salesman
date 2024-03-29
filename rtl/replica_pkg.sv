package replica_pkg;

parameter int replica_num = 160;
parameter int node_num = 16;
parameter int node_log = $clog2(node_num);
parameter int base_num = $ceil($itor(replica_num) / node_num);
parameter int base_log = $clog2(base_num);

parameter int city_num = 100;
parameter int city_num_log = $clog2(city_num);
parameter int city_div = $ceil($itor(city_num) / 8);
parameter int city_div_log = $clog2(city_div);

parameter int dbeta = 5;
parameter int siter_log = 10;

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
    logic [base_log-1:0] base_id;
    opt_command_t        com;
    logic [6:0]          K;
    logic [6:0]          L;
    logic [31:0]         r_metropolis;
    logic [31:0]         r_exchange;
} opt_t;

typedef logic [7:0][6:0] replica_data_t;
parameter replica_data_bit = 56;
typedef logic        [17:0] distance_data_t; // 1.17
typedef logic signed [20:0] delata_data_t;   // 3.17
typedef logic        [22:0] total_data_t;    // 6.17

endpackage : replica_pkg