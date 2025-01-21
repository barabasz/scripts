# makephar

A simple script for [zsh](https://www.zsh.org/) shell that allows you to quickly generate [Phar](https://www.php.net/manual/en/book.phar.php) files from projects placed in a folder with a specific name (`app` by default). There should be at least one file inside `app` folder called `main.php`.

## Usage

1. For convenience of use place both files (`makephar` and `makephar.php`) somewhere in your `$PATH` and make `makephar` executable. 
2. Place all required PHP files in the `app` directory and create a `main.php` file that calls the actual script (using [inculde](https://www.php.net/manual/en/function.include.php) or [require](https://www.php.net/manual/en/function.require.php)).
3. In the parent directory execute the `makephar` command.
4. `makephar` will generate Phar file called `app.phar`.
