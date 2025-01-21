# barabasz/scripts

More or less useful code snippets and little scripts in various languages (TS, JS, Python, VBA, C, DAX, SQL).

- [HP PPL](hp-ppl) - HP Prime Programming Language

## VBA

- [Bookmarks](vba/Bookmarks.vba) bunch of functions to handle bookmarks in Word
  - `GetBookmarkNames` returns collection with all bookmark names
  - `ReadTextFromBookmark`
  - `WriteTextToBookmark`
  - `ClearBookmark` clears bookmark content but left bookmark intact
  - `ClearAllBookmarks`
  - `RemoveBookmark` removes bookmark but left content intact
  - `RemoveAllBookmarks`
  - `RemoveBookmarkWithContent`
  - `RemoveAllBookmarkWithContent`
- [HexToVBAColor](vba/HexToVBAColor.vba) converts normal hex color values to VBA type, `hexColor` parameter can be a string in any of following formats: `#ff0000`, `ff0000`, `#f00`, `f00`. (VBA constructs color codes in very odd way by joining the BGR codes, so `#aabbcc` becomes `&Hccbbaa`)
- [CorrectDateFormat](vba/CorrectDateFormat.vba) normalize the date format to the ISO 8601:2004 standard

## PHP

- [urlinfo](php/urlinfo) is a simple PHP CLI wrapper around [cURL](https://www.php.net/manual/en/book.curl.php) that allows to display the most important information about the requested url in easy-to-read form.
