% GIT-FTP(1) git-ftp User Manual
% Rene Moser <mail@renemoser.net>
% 2013-12-01

# NAME

Git-ftp - Git powered FTP client written as shell script. 

# SYNOPSIS

git-ftp [actions] [options] [url]...

# DESCRIPTION

This manual page documents briefly the git-ftp program.

Git-ftp is a FTP client using Git to determine which local files to upload or which files should be deleted on the remote host.

It saves the deployed state by uploading the SHA1 hash in the .git-ftp.log file. There is no need for [Git] to be installed on the remote host.

Even if you play with different branches, git-ftp knows which files are different and only handles those files. No ordinary FTP client can do this and it saves time and bandwidth.

Another advantage is Git-ftp only handles files which are tracked with [Git].

# ACTIONS

`init`
:	Initializes the first upload to remote host.

`push`
:	Uploads files which have changed since last upload.

`catchup` 
:	Uploads the .git-ftp.log file only. We have already uploaded the files to remote host with a different program and want to remember its state by uploading the .git-ftp.log file.

`show`
:	Downloads last uploaded SHA1 from log and hooks \`git show\`.

`log`
:	Downloads last uploaded SHA1 from log and hooks \`git log\`.

`add-scope <scope>`
:	Creates a new scope (e.g. dev, production, testing, foobar). This is a wrapper action over git-config. See **SCOPES** section for more information.

`remove-scope <scope>`
:	Remove a scope.

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

`-A`, `--active`
:	Uses FTP active mode.

`-s [scope]`, `--scope [scope]`
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
:	Prints some usage information.

`-v`, `--verbose`
:	Be verbose.

`-vv`
:	Be as verbose as possible. Useful for debug information.

`--remote-root`
:	Specifies remote root directory

`--syncroot`
:	Specifies a local directory to sync from as if it were the git project root path.

`--key`
:	SSH Private key file name.

`--pubkey`
:	SSH Public key file name. Used with --key option.

`--insecure`
:	Don't verify server's certificate.

`--cacert <file>`
:	Use <file> as CA certificate store. Useful when a server has got a self-signed certificate. 

`--disable-epsv`
:	Tell curl to disable the use of the EPSV command when doing passive FTP transfers. Curl will normally always first attempt to use EPSV before PASV, but with this option, it will not try using EPSV.

`--version`
:	Prints version.

# URL

The scheme of an URL is what you would expect

	protocol://host.domain.tld:port/path

Below a full featured URL to *host.example.com* on port *2121* to path *mypath* using protocol *ftp*:

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

	$ git config git-ftp.<(url|user|password|syncroot|cacert)> <value>

Everyone likes examples:

	$ git config git-ftp.user john
	$ git config git-ftp.url ftp.example.com
	$ git config git-ftp.password secr3t
	$ git config git-ftp.syncroot path/dir
	$ git config git-ftp.cacert caCertStore
	$ git config git-ftp.deployedsha1file mySHA1File
	$ git config git-ftp.insecure 1
	$ git config git-ftp.key ~/.ssh/id_rsa

After setting those defaults, push to *john@ftp.example.com* is as simple as

	$ git ftp push

# SCOPES

Need different defaults per each system or environment? Use the so called scope feature.

Useful if you use multi environment development. Like a development, testing and a production environment.

	$ git config git-ftp.<scope>.<(url|user|password|syncroot|cacert)> <value>

So in the case below you would set a testing scope and a production scope.

Here we set the params for the scope "testing"

	$ git config git-ftp.testing.url ftp.testing.com:8080/foobar-path
	$ git config git-ftp.testing.password simp3l

Here we set the params for the scope "production"

	$ git config git-ftp.production.user manager
	$ git config git-ftp.production.url live.example.com
	$ git config git-ftp.production.password n0tThatSimp3l

Pushing to scope *testing* alias *john@ftp.testing.com:8080/foobar-path* using password *simp3l*

	$ git ftp push -s testing

*Note:* The **SCOPE** feature can be mixed with the **DEFAULTS** feature. Because we didn't set the user for this scope, git-ftp uses *john* as user as set before in **DEFAULTS**.

Pushing to scope *production* alias *manager@live.example.com* using 
password *n0tThatSimp3l*

	$ git ftp push -s production

*Hint:* If your scope name is identical with your branch name. You can skip the scope argument, e.g. if your current branch is "production":

	$ git ftp push -s

You can also create scopes using the add-scope action. All settings can be defined in the URL.
Here we create the *production* scope using add-scope

	$ git ftp add-scope production ftp://manager:n0tThatSimp3l@live.example.com/foobar-path

Deleting scopes is easy using the `remove-scope` action.

	$ git ftp remove-scope production

# IGNORING FILES TO BE SYNCED

Add file names to `.git-ftp-ignore` to be ignored.

Ignoring all in Directory `config`:

	config/.*

Ignoring all files having extension `.txt` in `./` :

	.*\.txt

This ignores `a.txt` and `b.txt` but not `dir/c.txt`

Ignoring a single file called `foobar.txt`:

	foobar\.txt

# SYNCING UNTRACKED FILES

To upload an untracked file when a paired tracked file changes (e.g. uploading a compiled CSS file when its source SCSS or LESS file changes), add a file pair to `.git-ftp-include`:

	css/style.css:scss/style.scss

If you have multiple source files being combined into a single untracked file, you can pair the untracked file with multiple tracked files, one per line. This ensures the combined untracked file is properly uploaded when any of the component tracked files change:

	css/style.css:scss/style.scss
	css/style.css:scss/mixins.scss

# NETRC

In the backend, Git-ftp uses curl. This means `~/.netrc` could be used beside the other options of Git-ftp to authenticate.

	$ editor ~/.netrc
	machine ftp.example.com
	login john
	password SECRET

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

The upstream BTS can be found at <https://github.com/git-ftp/git-ftp/issues>.

[Git]: http://git-scm.org
