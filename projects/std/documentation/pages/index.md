# `std`

Valkyrie standard library.

## Collection indexing

Two index contracts exist; a type implements one or both.

| Contract | Operator | Base | Applies to |
|:---------|:---------|:-----|:-----------|
| `Cardinal` | `⁅ ⁆` / `⁅ ⁆=` | 0-based offset | sequences: `Array`, `ArrayList`, `ArrayView`, `Utf8Text`, `Utf16Text` |
| `Ordinal` | `[ ]` / `[ ]=` | ordinal | sequences (position), maps and sets (key) |

### Maps and sets

`HashMap`, `HashSet`, `BTreeMap`, `BTreeSet` implement **only** `Ordinal`, with
`Index = K`: the index is the key, not a position. `Cardinal` (`⁅ ⁆`) has no
implementation for these types.

- read: `container[key]` returns the value (sets: the stored element) and fails
  structurally when the key is absent; `get(key)` is the recoverable form and
  returns `None` instead.
- write: `container[key] = value` is the same storage path as `insert`; for an
  absent key it inserts, for a present key it overwrites the value (sets keep a
  single element per key).
- delete: use the type's own `remove`, which reports absence via `Option`/`bool`.
- `length()` is the number of entries, never an index space.

`git`-tracked counter-example for the missing `Cardinal` path:
`projects/std/negative/cardinal_on_map_set.v` (expected to fail at compile time).
