% GIT-FTP(1) git-ftp User Manual
% Rene Moser <mail@renemoser.net>
% December 23, 2010

# NAME

Git-ftp - FTP done the Git way 

# SYNOPSIS

git-ftp [actions] [options] [url]...

# DESCRIPTION

This manual page documents briefly the git-ftp programm.

Git-ftp is a FTP client using Git to find out which files to upload or which files should be deleted on the remote host. 

It saves the deployed state by uploading the SHA1 hash in the .git-ftp.log file. There is no need for [Git] to be installed on the remote host.

Even if you play with different branches, git-ftp knows which files are different and only handles those files. No ordinary FTP client can do this and it saves time and bandwith.

Another advantage is Git-ftp only handles files which are tracked with [Git]. 

# ACTIONS

`push`
:	Syncs your current Git checked out branch with a remote host. 

`catchup` 
:	Uploads the .git-ftp.log file only. You have already uploaded the files to FTP with a different programm and you only want to remember its state by uploading the .git-ftp.log file.

`show`
:	Prints the last uploaded commit log.

`help`
:	Prints a usage help.

# OPTIONS

`-u <username>`, `--user <username>`
:	FTP login name.

`-p [password]`, `--passwd [password]`
:	FTP password. If no argument is given, a password prompt will be shown.

`-k <account>`, `--keychain <account>`
:	FTP password from KeyChain (Mac OS X only).

`-a`, `--all`
:	Uploads all files of current Git checkout.

`-s <scope>`, `--scope <scope>`
:	Using a scope (e.g. dev, production, testing, foobar). See **SCOPE** and **DEFAULTS** section for more information.

`-l`, `--lock`
:	Enable remote locking.

`-D`, `--dry-run`
:	Does not upload or delete anything, but tries to get the .git-ftp.log file from remote host.

`-f`, `--force`
:	Does not ask any questions, it just does.

`-n`, `--silent`
:	Be silent.

`-h`, `--help`
:	Prints some usage informations.

`-v`, `--verbose`
:	Be verbosy.

`--version`
:	Prints version.

# URL

The scheme of an URL is what you would expect

	protocol://host.domain.tld:port/path
	
Below a full feature URL to *host.exmaple.com* on port *2121* to path *mypath* using protocol *ftp*:

	ftp://host.example.com:2121/mypath

But, there is not just FTP. Supported protocols are:

`ftp://...`
:	FTP (default if no protocol is set)

`sftp://...`
:	SFTP

`ftps://...`
:	FTPS

`ftpes://...`
:	FTP over explicit SSL (FTPES) protocol

# DEFAULTS

Setting defaults for git-ftp in .git/config
	
	$ git config git-ftp.<(url|user|password)> <value>

Everyone likes examples

	$ git config git-ftp.user john
	$ git config git-ftp.url ftp.example.com
	$ git config git-ftp.password secr3t

After setting those defaults, push to *john@ftp.example.com* is as simple as

	$ git ftp push

# SCOPES

For different defaults per system, use the so called scope feature. 

Useful if you have different systems you want to FTP to, like a testing system and a production system. So in this case you would set a testing scope and a production scope.

	$ git config git-ftp.<scope>.<(url|user|password)> <value>

Here I set the params for the scope "foobar"

	$ git config git-ftp.foobar.url ftp.testing.com:8080/foobar-path
	$ git config git-ftp.foobar.password simp3l

Push to scope *foobar* alias *john@ftp.testing.com:8080/foobar-path* using 
password *simp3l*

	$ git ftp push -s foobar

Because we didn't set the user for this scope, git-ftp uses *john* as user as set before in **DEFAULTS**.


# EXIT CODES
There are a bunch of different error codes and their corresponding error messages that may appear during bad conditions. At the time of this writing, the exit codes are:

`1`
:	Unkonwn error

`2`
:	Wrong Usage

`3`
:	Missing arguments

`4`
:	Error while uploading

`5`
:	Error while downloading

`6`
:	Unknown protocol

`7`
:	Remote locked

`8`
:	Not a Git project

# KNOWN ISSUES & BUGS

Git submodules are currently not supported. The upstream BTS can be found at <http://github.com/resmo/git-ftp/issues>.

[Git]: http://git-scm.org
