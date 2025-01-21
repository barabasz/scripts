def clean_string(string: str) -> str:
    clean_string = ""
    for char in string.lower():
        if char.isalpha() or char.isdigit() or char.isspace():
            clean_string += char
    return clean_string


def same_word_counter(string: str) -> dict:
    str_cln = clean_string(string)
    str_lst = str_cln.split()
    str_set = set(str_lst)
    str_dct = {k: str_lst.count(k) for k in str_lst}
    return dict(sorted(str_dct.items(), key=lambda x:x[1], reverse = True))


s = "One 4, 4 three two; 4 three two, three 4."
print(same_word_counter(s))