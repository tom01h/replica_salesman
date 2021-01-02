- [x] レプリカテストの結果を受け取って、ordering メモリの or-opt と 2-opt とレプリカ交換
- [x] Δ距離の計算
- [x] メトロポリステストの結果を受け取って、合計距離の計算
- [x] 合成できない計算を使って全体を動かす
- [x] 合成できる
- [ ] インタフェースをつけて FPGA で実行
- [ ] 4段パイプライン化
- [ ] 50node・200レプリカ

## RTL シミュレーションを実行する

### Verilator ← 今は動かない

Verilator の出力した C++ のコードを使って Python の C++ モジュールを作成して検証します。

まずは、RTL から Python モジュールをコンパイルします。

コンパイルには Python3 と Verilator が必要です。

```
replica_salesman/sim$ make
```

シミュレーションを実行すると、波形ファイル `tmp.vcd` ができます。

```
replica_salesman/sim$ python3 replica_salesman_sim.py
```

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

