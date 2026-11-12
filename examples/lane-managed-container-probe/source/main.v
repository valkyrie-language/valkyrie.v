namespace lane.probe;

using std.collection;

[main]
micro main() -> i32 {
    let mut map: HashMap<i64, i64> = HashMap::new(0)
    map.insert(1, 10)
    map.insert(2, 20)
    map.insert(3, 30)

    let keys: ArrayList<i64> = map.keys()
    let values: ArrayList<i64> = map.values()

    let mut total: i32 = 0
    total = total + keys.length() as i32
    total = total + values.length() as i32
    return total
}
