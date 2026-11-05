# `std`

Valkyrie 标准库。

## 集合索引合同

库内有两套索引合同，一个类型可以实现其中一套或两套。

| 合同 | 算子 | 基数 | 适用 |
|:-----|:-----|:-----|:-----|
| `Cardinal` | `⁅ ⁆` / `⁅ ⁆=` | 0 基偏移 | 序列：`Array`、`ArrayList`、`ArrayView`、`Utf8Text`、`Utf16Text` |
| `Ordinal` | `[ ]` / `[ ]=` | 序数 | 序列（位置）、映射与集合（键） |

### 映射与集合

`HashMap`、`HashSet`、`BTreeMap`、`BTreeSet` **只实现** `Ordinal`，且 `Index = K`：
索引就是键，不是位置。`Cardinal`（`⁅ ⁆`）对它们没有实现、不存在入口。

- 读：`container[key]` 返回裸值（集合返回存储的元素），键缺失时结构化失败；
  可恢复形态是 `get(key)`，键缺失返回 `None`。
- 写：`container[key] = value` 与 `insert` 共用同一条存储路径；缺键即新增，
  已有键则覆盖值（集合每个键只保留一个元素）。
- 删：走类型自身的 `remove`，缺席通过 `Option` / `bool` 报告。
- `length()` 恒为条目数，与索引空间无关。

`Cardinal` 缺席的编译期反例：`projects/std/negative/cardinal_on_map_set.v`
（预期在编译期失败）。
