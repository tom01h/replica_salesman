# レプリカ交換法で巡回セールスマン問題を解く

書籍 [ゼロからできる MCMC](https://www.kspub.co.jp/book/detail/5201749.html) のサンプルコードを参考にして、FPGA で計算する回路を目指します。

最初に、書籍のサンプルコードを Python に翻訳、レプリカ交換を並列実行可能とするために N,N+1 の交換と N-1,N の交換を交互に実行するよう変更、その後に新ルートの提案アルゴリズムを [これ](http://www.nct9.ne.jp/m_hiroi/light/pyalgo64.html) を参考に 2-opt 法と簡易 or-opt 法のチクタクに変更しました。

その辺の経過は [こちらのリポジトリ](https://github.com/tom01h/TIL/tree/master/MCMC-Sample-Codes) にあります。

ここでは RTL 化を管理します。相変わらず管理がへたくそ…

### ブロック図

目指しているのはこんなの。16*2node 並べる予定。

![ブロック図](ブロック図.svg)

距離データは比較に使ったデータを選択してレプリカ交換にも使う。

実際には or-opt 用のノードと 2-opt 用のノードを別にして↓のような構成で、レプリカ交換時に隣のノードにデータを渡す。

![node](node.svg)

### 実行

動作モデルの実行は以下。

RTL に使う乱数発生器のモデルは `xor64.cpp` に記述しています。  
exp の近似計算は `fmath.cpp` に記述しています。  
その他は `replica_salesman.py` の中です。

```
python3 setup.py build_ext -I/usr/local/share/verilator/include -i
python3 replica_salesman.py
```

RTL シミュレーションは sim/ 下に説明があります。  
Python の動作モデルの結果と比較しながら検証できます。

FPGA で実行する説明は fpga/ 下にあります。  
Ultra96 (初代) と LiteFury で試しています。

### アルゴリズムを簡単に説明

#### 簡易 or-opt 法

ルート中の k 番目の都市を l 番目の都市の後ろに移動する。

```
p = ordering[k]
ordering_fin = np.hstack((ordering[0:k], ordering[k+1:]))
ordering_fin = np.hstack((ordering_fin[0:l],   p, ordering_fin[l:]))
```



![or-opt](or-opt.svg)

#### 2-opt 法

k-1 番目と k 番目の都市の接続と l-1 番目と l 番目の都市の接続を入れ替える (ただし k<l) 。

```
ordering_fin = np.hstack((ordering[0:k], ordering[k:l][::-1], ordering[l:]))
```



![2-opt](2-opt.svg)

#### メトロポリス法

上記の交換で提案された新しいルートと、そのもとになったルートの距離の差を Δr としたときに、

```
min(1, exp(-Δr/T))
```

の確率で新ルートを採用する。

距離が短くなる時は 100% 受理、長くなるにつれて棄却率が高くなる。

温度 T によっても確率が変わる (温度が高いと受理する確率が上がる) 。

![metropolis](metropolis.svg)

#### レプリカ交換法

複数の温度でメトロポリス法を実行。隣り合う温度のルートを交換する。温度が高いほうが距離が短ければ 100% 受理、長くなるにつれて棄却率が高くなる。並列処理をするために、交換は隣の温度と交互に実行。

![replica](replica.svg)