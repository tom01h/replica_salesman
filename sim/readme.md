- [x]  経過と最短経路の保存
- [ ] 10段パイプ・10node
- [ ] 1,2,4レプリカ/node
- [x] 100都市

## RTL シミュレーションを実行する

### Verilator(保留)

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

DPI-C と mmap を使った Python と C のプロセス間通信を使って検証します。

Windows 版の ModelSim と Windows 版の Python 32bit 版 と Microsoft Visual C++ 14.0 (Microsoft Visual C++ Build Tools) が必要です。

Windows に [パス設定](https://github.com/tom01h/TIL/tree/master/dpi-python#%E6%BA%96%E5%82%99) が必要です。その他にも、シミュレータの構成はリンク先が参考になります。

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
- top.py
- lib.cpp
- replica_salesman_sim.py

こんな文字列 `from . import ft2font` 含むエラー出たら、matplotlib のバージョンを下げるとよいらしいです

```
pip3.exe uninstall matplotlib
pip3.exe install matplotlib==3.0.3
```

