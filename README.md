[![Build Status](https://travis-ci.org/git-ftp/git-ftp.svg?branch=develop)](https://travis-ci.org/git-ftp/git-ftp)

README of git-ftp
=================

* This application is licensed under [GNU General Public License, Version 3.0]
* Follow this project on twitter [@gitftp](https://twitter.com/gitftp)

Summary
-------

Git powered FTP client written as shell script. modified by oshanrube to add mysql sync. you can visit the main project on https://travis-ci.org/git-ftp/git-ftp


About
-----

I use git-ftp for my script based projects, mostly PHP. Most of the low-cost
web hosting companies do not provide SSH or git support, but only FTP.

That is why I needed an easy way to deploy my git tracked projects. Instead of
transferring the whole project, I thought, why not only transfer the files
that changed since the last time, git can tell me those files.

Even if you are playing with different branches, git-ftp knows which files
are different. No ordinary FTP client can do that.


Known Issues
------------

* See [git-ftp issues on GitHub] for open issues


Installing
----------

See [INSTALL](INSTALL.md) file.


Usage
-----

set the configuration into the git config
	. git config git-ftp.user john
	. git config git-ftp.url ftp.example.com
	. git config git-ftp.password secr3t
	. git config git-ftp.remote-root "~/www/"
	. git config git-ftp.syncroot path/dir
	. git config git-ftp.cacert path/cacert
	. git config git-ftp.deployedsha1file mySHA1File
	. git config git-ftp.insecure 1
	. git config git-ftp.mysql_username mysql_user
	. git config git-ftp.mysql_password mysql_pass
	. git config git-ftp.mysql_database mysql_db
	. git config git-ftp.mysql_hostname mysql_host
	. git config git-ftp.mysql_server_username mysql_user
	. git config git-ftp.mysql_server_password mysql_pass
	. git config git-ftp.mysql_server_database mysql_db
	. git config git-ftp.mysql_server_hostname mysql_host
	. git config git-ftp.websiteurl http://url.com/

or you can pass them inline
``` sh
$ cd my_git_tracked_project
$ git ftp push --user <user> --passwd <password> ftp://host.example.com/public_html
```

For interactive password prompt use:

``` sh
$ git ftp push -u <user> -p - ftp://host.example.com/public_html
```

Pushing for the first time:

``` sh
$ git ftp init -u <user> -p - ftp://host.example.com/public_html
```

See [man page](man/git-ftp.1.md) for more options, features and examples!


Limitations
-----------

* Windows and OS X: I am very limited in testing on Windows and OS X. Thanks for helping me out fixing bugs on these platforms.
* git-ftp as deployment tool: git-ftp was not designed as centralized deployment tool. While running git-ftp, you have to take care, no one pushes or touches this repo (e.g. no commits, no checkouts, no file modifications)!


Unit Tested
-----------

Core functionality is unit tested on Linux using shunit2. You can find the tests in `tests/`.


Contributions
-------------

Don't hesitate to use GitHub to improve this tool. Don't forget to add yourself to the [AUTHORS](AUTHORS) file.

[git-ftp issues on GitHub]: http://github.com/git-ftp/git-ftp/issues
[GNU General Public License, Version 3.0]: http://www.gnu.org/licenses/gpl-3.0-standalone.html
