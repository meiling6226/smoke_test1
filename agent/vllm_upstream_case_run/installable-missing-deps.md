# 可安装的缺失依赖

镜像里没有、但可以用 pip 装上的依赖记在这里，不要写进 known-errors.md。

已安装的依赖版本不匹配，如果是共性问题，写进 known-errors.md，不要为了让用例通过去改版本。单个用例>特有的签名或版本差异不要写进去。

## mteb

报错：`ModuleNotFoundError: No module named 'mteb'`

安装：

```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple 'mteb[bm25s]'
```