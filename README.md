# barabasz/scripts

More or less useful code snippets and little scripts in various languages (TS, JS, Python, VBA, C, DAX, SQL).

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

### urlinfo

[[php/urlinfo.php|urlinfo]] is a simple PHP CLI wrapper around [cURL](https://www.php.net/manual/en/book.curl.php) that allows to display the most important information about the requested url in easy-to-read form.

#### Usage

`urlinfo [options] URL`

Arguments:

`URL` - url to request

Options:

    -b      show body (only for unencoded text/plain content) 
    -c      print verbose cURL info (without SSL info)
    -f      ignore SSL errors
    -H      print this info and exit
    -h      print verbose response headers (without cookies and CSP)
    -i      print verbose ipinfo
    -m      mute standard output
    -p      force plain text content response
    -t      show script execution time
    -v      print version and exit

#### Remarks

- TTFB (Time to First Byte)  is calculated as a time between final request (GET send by the client after TCP handshake and SSL handshake) and first byte recieved (difference between `time_pretransfer` and `time_starttransfer`). 
- Time of transfer is calculated as a time betwenen total time (`time_total`) and a time the first byte was just about to be transferred (`time_starttransfer`).
- Total time is calculated as a total time for this request, including name resolving, handshaking and transfer.
