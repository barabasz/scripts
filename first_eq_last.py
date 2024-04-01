def first_eq_last(nums: list, item: any) -> bool:
    if len(nums):
        return nums[0] == item == nums[-1]
    else:
        return False

nums = ['a', 'b', 'c', 'a']
print(first_eq_last(nums, 'a'))

nums = [1, 2, 3, 1]
print(first_eq_last(nums, 1))
