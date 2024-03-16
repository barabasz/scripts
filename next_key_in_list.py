from typing import Any


def next_key(lst: list, key: Any) -> Any:
    try:
        res = lst[lst.index(key) + 1]
    except (ValueError, IndexError):
        res = None
    return res


l1 = ["a", "b", "c", "d", "e"]
print(next_key(l1, "c"))

l2 = [11, 12, 13, 14, 15]
print(next_key(l2, 12))
