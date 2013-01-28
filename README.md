README of git-ftp
=================

* &copy; René Moser, mail@renemoser.net, 2010-2012
* This application is licenced under [GNU General Public License, Version 3.0]

This is free and open source software. If you like and use it, flattr it ([flattr?][WhatisFlattr]). Thx.

[![][FlattrButton]][FlattrLink] 


Summary
-------

Git powered FTP client written as shell script.


About
-----

I use git-ftp for my script based projects, mostly PHP. Most of the low-cost
web hosting companies do not provide SSH or git support, but only FTP.

That is why I needed an easy way to deploy my git tracked projects. Instead of
transfering the whole project, I thought, why not only transfer the files
that changed since the last time, git can tell me those files.

Even if you are playing with different branches, git-ftp knows which files
are different. No ordinary FTP client can do that.


Known Issues
------------

* See [git-ftp issues on GitHub] for open issues


Installing
----------

See INSTALL file.


Usage
-----

	$ cd my_git_tracked_project
	$ git ftp push --user <user> --passwd <password> ftp://host.example.com/public_html

For interactive password prompt use:

	$ git ftp push -u <user> -p - ftp://host.example.com/public_html

Pushing for the first time:

	$ git ftp init -u <user> -p - ftp://host.example.com/public_html

Using Defaults
--------------

Setting defaults for a git project in .git/config

	$ git config git-ftp.user john
	$ git config git-ftp.url ftp.example.com
	$ git config git-ftp.password secr3t
	$ git config git-ftp.cacert caCertStore
	$ git config deployedsha1file mySHA1File
	$ git config syncroot Output
	$ git config curl-insecure 1
	

After setting defaults, push to `john@ftp.example.com` is as simple as

	$ git ftp push


Using Scopes
------------

For using defaults for different systems, use the so called scope feature.

	$ git config git-ftp.<scope>.<(param)> <value>
	with param := {url|user|password|cacert|syncroot|curl-insecure|deployedsha1file}

Here I set the params for the scope `foobar`

	$ git config git-ftp.foobar.url ftp.testing.com:8080/foobar-path
	$ git config git-ftp.foobar.password simp3l

Set scope params using action `add-scope`

	$ git ftp add-scope foobar ftp://username:simp3l@ftp.testing.com:8080/foobar-path

You can also remove a previously set scope using `remove-scope`

	$ git ftp remove-scope foobar

Push to scope `foobar` alias `john@ftp.testing.com:8080/foobar-path` using password `simp3l`

	$ git ftp push -s foobar

Because I didn't set the user for this scope, it takes the user `john` as set before in defaults.


Ignoring Files to be synced
---------------------------

Add file names to `.git-ftp-ignore` to be ignored.

Unlike `.gitignore`, the pattern matching uses regular expressions (instead of globbing).

Ignoring all in directory `config`:

	config/.*

Ignoring all files having extension `.txt` in `./` :

	.*\.txt

This ignores `a.txt` and `b.txt` but not `dir/c.txt`

Ignoring a single file called `foobar.txt`:

	foobar\.txt


Testing and Help Manual
-----------------------

For testing mode use `--dry-run` alias `-D`

	$ git ftp push -u <user> -p --dry-run ftp://host.example.com/public_html

For more options and features see man page or help:

	$ git ftp help


Unit Tested
-----------

Core functionality is unit tested on Linux using shunit2. You can find the tests in `tests/`.


Contributions
-------------

Don't hesitate to use GitHub to improve this tool. Don't forget to add yourself to the AUTHORS file.

[git-ftp issues on GitHub]: http://github.com/resmo/git-ftp/issues
[WhatisFlattr]: http://en.wikipedia.org/wiki/Flattr
[FlattrLink]: https://flattr.com/thing/99914/Git-ftp
[FlattrButton]: http://api.flattr.com/button/button-static-50x60.png
[GNU General Public License, Version 3.0]: http://www.gnu.org/licenses/gpl-3.0-standalone.html
