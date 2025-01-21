"""
Finds the most common item in the list
"""


def find_most_common_item(num_list: list):
    counts = {}
    for n in num_list:
        counts[n] = counts.get(n, 0) + 1
    return max(counts, key=counts.get)


def find_most_common_item2(num_list: list):
    d = {i: num_list.count(i) for i in set(num_list)}
    return [i for i in d if d[i] == max(d.values())][0]


numbers = [1, 7, 8, 5, 5, 7, 7, 7, 8, 8, 5]
print(find_most_common_item(numbers))
print(find_most_common_item2(numbers))
letters = ['a', 'b', 'c', 'd', 'd', 'b', 'b', 'b', 'e', 'e', 'd']
print(find_most_common_item(letters))
print(find_most_common_item2(letters))
