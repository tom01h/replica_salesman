# FPGA で実行する

### ブロックデザインを作る

`replica_salesman/syn/U96` にて合成します

[NahiViva](https://github.com/tokuden/NahiViva) で再現できるようにしました。説明は [こっち](http://nahitafu.cocolog-nifty.com/nahitafu/2019/05/post-2cfa5c.html) を見た方が良いかも。  
必要なファイルをダウンロードして、`open_project_gui.cmd` 実行でプロジェクトが再現されます。

### ファイルを転送する

FPGA の Linux に以下のファイルをコピーする

- replica_salesman_fpga.py
- setup.py
- lib.cpp
- top.py

FPGA の Linux に ~/bit ディレクトリを作成し、以下のファイルをリネームしてコピーする

`replica_salesman/syn/U96/sensors96b/sensors96b.srcs/sources_1/bd/sensors96b/hw_handoff/` から

- sensors96b.hwh を replica_salesman.hwh にリネームしてコピー

- sensors96b_bd.tcl を replica_salesman.tcl にリネームしてコピー

`replica_salesman/syn/U96/sensors96b/sensors96b.runs/impl_1/` から

- sensors96b_wrapper.bit を replica_salesman.bit にリネームしてコピー

### 実行する

最初の1回だけ準備が必要

```
xilinx@pynq:~$ python3 setup.py build_ext -i
```

その後は、

```
xilinx@pynq:~$ sudo python3 replica_salesman_fpga.py
```

