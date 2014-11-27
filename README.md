*findr* is a ruby find and replace tool for mass editing of text files using (advanced) regular expressions.

[![Build Status](https://travis-ci.org/mstrauss/findr.svg)](https://travis-ci.org/mstrauss/findr)

Usage
-----

    Usage: findr [options] <search regex> [<replacement string>]
        -g, --glob FILE SEARCH GLOB      e.g. "*.{rb,erb}"
        -x, --execute                    actually execute the replacement
        -c, --coding FILE CODING SYSTEM  e.g. "iso-8859-1"
        -s, --save                       saves your options to .findr-config for future use
        -C, --codings-list               list available encodings

*findr* recursively searches for the given [regular expression](http://rubular.com) in all files matching the given [glob](http://www.ruby-doc.org/core-2.1.5/Dir.html#method-c-glob), **starting from the current subdirectory**.


Basic Examples
--------------

* To **search the term** 123.456 in all `txt`-files:

        findr -g '*.txt' 123\\.456

    The `*.txt` must be escaped (from the shell) by using apostrophes, otherwise the shell might expand it to the names of `txt` files in the current directory.

    The dot must be escaped (from the regexp parser), otherwise is would stand for *any* character.  To escape the dot---on most shells---you could either write two backslashes to feed one backslash into the program, or put the command under single apostrophes, like

        findr '123\.456'


* To **replace the term** 123.456 by 33.0:

        findr '123\.456' 33.0

    The previous command shows a preview of what would happen. Adding `-x` executes the change and irreversibly alters your files:

        findr 123\.456 33.0 -x


* To do a **case-insensitive search** for `word` use

        findr '(?i:word)'


Advanced Examples
-----------------

* A more complicated example:  *findr* allows to **use matches** in the replacement string and also allows the use of advanced regular expression features like **lazy matching**.  Consider the following input file `example.txt`:

        a = 99
        b=123;
        var  = 44
        d = 55 ;
        x=

    Say, you want to normalize it in a way that there is exactly one space before and after the equal sign and each line should end with an semicolon.  One way to do it:

        findr -g example.txt '(.*?)\s*=\s*(.*?)[\s;]*$' '\1 = \2;' -x

    `\s` stands for any whitespace character.  `.*?` lazily matches any character, until the following expression (here `[\s;]*$`) matches.  The `$` sign is necessary to make the second lazy matcher `.*?` not *too* lazy.  The lazy matcher gives the *minimal* string possible to fulfill the regular expression--even when this means aborting prematurely. So, we need to take the line end matcher `$` into the regexp.

    This changes `example.txt` to:

        a = 99;
        b = 123;
        var = 44;
        d = 55;
        x = ;
