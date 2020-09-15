# レプリカ交換法で巡回セールスマン問題を解く

書籍 [ゼロからできる MCMC](https://www.kspub.co.jp/book/detail/5201749.html) のサンプルコードを参考にして、FPGA で計算する回路を目指します。

最初に、書籍のサンプルコードを Python に翻訳、レプリカ交換を並列実行可能とするために N,N+1 の交換と N-1,N の交換を交互に実行するよう変更、その後に新ルートの提案アルゴリズムを [これ](http://www.nct9.ne.jp/m_hiroi/light/pyalgo64.html) を参考に 2-opt 法と簡易 or-opt 法のチクタクに変更しました。

その辺の経過は [こちらのリポジトリ](https://github.com/tom01h/TIL/tree/master/MCMC-Sample-Codes) にあります。

ここでは RTL 化を管理します。相変わらず管理がへたくそ…