% GIT-FTP(1) git-ftp User Manual
% Rene Moser <mail@renemoser.net>
% December 23, 2010

# NAME

Git-ftp - FTP done the Git way 

# SYNOPSIS

git-ftp [actions] [options] [url]...

# DESCRIPTION

This manual page documents briefly the git-ftp programm.

Git-ftp is a FTP client using Git to determine which local files to upload or which files should be deleted on the remote host. 

It saves the deployed state by uploading the SHA1 hash in the .git-ftp.log file. There is no need for [Git] to be installed on the remote host.

Even if you play with different branches, git-ftp knows which files are different and only handles those files. No ordinary FTP client can do this and it saves time and bandwith.

Another advantage is Git-ftp only handles files which are tracked with [Git]. 

# ACTIONS

`init`
:	Initializes the first upload to remote host.

`push`
:	Uploads files which have changed since last upload.

`catchup` 
:	Uploads the .git-ftp.log file only. We have already uploaded the files to remote host with a different programm and want to remember its state by uploading the .git-ftp.log file.

`show`
:	Downloads last uploaded SHA1 from log and hooks \`git show\`.

`help`
:	Prints a usage help.

# OPTIONS

`-u [username]`, `--user [username]`
:	FTP login name. If no argument is given, local user will be taken.

`-p [password]`, `--passwd [password]`
:	FTP password. If no argument is given, a password prompt will be shown.

`-k [[user]@[account]]`, `--keychain [[user]@[account]]`
:	FTP password from KeyChain (Mac OS X only).

`-a`, `--all`
:	Uploads all files of current Git checkout.

`-c`, `--commit`
:	Sets the SHA1 hash of last deployed commit by option.

`-A`, `--active`
:	Uses FTP active mode.

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

`-vv`
:	Be verbosy as much as possible.

`--syncroot`
:	Specifies a directory to sync from as if it were the git project root path.

`--connections`
:	Number of simultanious connections (Linux only).

`--version`
:	Prints version.

# URL

The scheme of an URL is what you would expect

	protocol://host.domain.tld:port/path
	
Below a full featured URL to *host.exmaple.com* on port *2121* to path *mypath* using protocol *ftp*:

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

Don't repeat yourself. Setting defaults for git-ftp in .git/config
	
	$ git config git-ftp.<(url|user|password)> <value>

Everyone likes examples

	$ git config git-ftp.user john
	$ git config git-ftp.url ftp.example.com
	$ git config git-ftp.password secr3t
	$ git config git-ftp.connections 10
	$ git config git-ftp.syncroot path/dir

After setting those defaults, push to *john@ftp.example.com* is as simple as

	$ git ftp push

# SCOPES

Need different defaults per each system or environment? Use the so called scope feature.

Useful if you use multi environment development. Like a development, testing and a production environment. 

	$ git config git-ftp.<scope>.<(url|user|password)> <value>

So in the case below you would set a testing scope and a production scope.

Here we set the params for the scope "testing"

	$ git config git-ftp.testing.url ftp.testing.com:8080/foobar-path
	$ git config git-ftp.testing.password simp3l

Here we set the params for the scope "production"

	$ git config git-ftp.production.user manager
	$ git config git-ftp.production.url live.example.com
	$ git config git-ftp.production.password n0tThatSimp3l


Pushing to scope *testing* alias *john@ftp.testing.com:8080/foobar-path* using 
password *simp3l*

	$ git ftp push -s testing

*Note:* The **SCOPE** feature can be mixed with the **DEFAULTS** feature. Because we didn't set the user for this scope, git-ftp uses *john* as user as set before in **DEFAULTS**.

Pushing to scope *production* alias *manager@live.example.com* using 
password *n0tThatSimp3l*

	$ git ftp push -s production


# IGNORING FILES

Add file names to `.git-ftp-ignore` to be ignored.

Ignoring all in Directory `config`:

	config/*

Ignoring all files having extension `.txt` in `./` :

	*.txt

This ignores `a.txt` and `b.txt` but not `dir/c.txt`

Ingnoring a single file called `gargantubrain.txt`:

	gargantubrain.txt


# EXIT CODES
There are a bunch of different error codes and their corresponding error messages that may appear during bad conditions. At the time of this writing, the exit codes are:

`1`
:	Unknown error

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

The upstream BTS can be found at <http://github.com/resmo/git-ftp/issues>.

[Git]: http://git-scm.org
