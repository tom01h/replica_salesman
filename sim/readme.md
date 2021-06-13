- [x] インタフェースをつける
- [x] or_node と two_node を分離
- [x] 8回の時分割
- [ ] 8段パイプライン化
- [ ]  FPGA で実行
- [ ]  経過と最短経路の保存
- [ ] 25node・200レプリカ

## RTL シミュレーションを実行する

### Verilator

Verilator の出力した C++ のコードを使って Python の C++ モジュールを作成して検証します。

まずは、RTL から Python モジュールをコンパイルします。

WSL版の Python3 と Verilator が必要です。

```
replica_salesman/sim$ make
```

シミュレーションを実行すると、波形ファイル `tmp.vcd` ができます。

```
replica_salesman/sim$ python3 replica_salesman_sim.py
```

テストベンチを構成するファイル

- top.cpp

Verilator のバージョンは Verilator 4.202 2021-04-24 rev v4.202

### MidelSim (Windows 版)

DPI-C と Python-API を使って検証します。

Windows 版の ModelSim と Windows 版の Python 32bit 版が必要です。

ビルド＆RUN

```
replica_salesman/sim$ ./build.sh
```

RUN のみ

```
replica_salesman/sim$ ./run.sh
```

テストベンチを構成するファイル

- tb.sv
- tb.cpp
- replica_salesman_sim.py