% GIT-FTP(1) Git-ftp 1.5.1
%
% 2018-05-15

# NAME

Git-ftp - Git powered FTP client written as shell script.

# SYNOPSIS

*git-ftp* \<action\> [\<options\>] [\<url\>]

# DESCRIPTION

Git-ftp is an FTP client using [Git] to determine which local files to upload or
which files to delete on the remote host.

It saves the deployed state by uploading the SHA1 hash in the `.git-ftp.log`
file. There is no need for Git to be installed on the remote host.

Even if you play with different branches, git-ftp knows which files are
different and handles only those files. That saves time and bandwidth.

# ACTIONS

`init`
:	Uploads all git-tracked non-ignored files to the remote server and
	creates the `.git-ftp.log` file containing the SHA1 of the latest
	commit.

`catchup`
:	Creates or updates the `.git-ftp.log` file on the remote host.
	It assumes that you uploaded all other files already.
	You might have done that with another program.

`push`
:	Uploads files that have changed and
	deletes files that have been deleted since the last upload.
	If you are using GIT LFS, this uploads LFS link files, 
	not large files (stored on LFS server). 
	To upload the LFS tracked files, run `git lfs pull`
	before `git ftp push`: LFS link files will be replaced with 
	large files so they can be uploaded.  

`download` (EXPERIMENTAL)
:	Downloads changes from the remote host into your working tree.
	This feature needs lftp to be installed and does not use any power of
	Git.
	WARNING: It can delete local untracked files that are not listed in
	your `.git-ftp-ignore` file.

`pull` (EXPERIMENTAL)
:	Downloads changes from the remote host into a separate commit
	and merges that into your current branch.
	This feature needs lftp to be installed.

`snapshot` (EXPERIMENTAL)
:	Downloads files into a new Git repository. Takes an additional
	argument as local destination directory. Example:
	\`git-ftp snapshot ftp://example.com/public_html projects/example\`
	This feature needs lftp to be installed.

`show`
:	Downloads last uploaded SHA1 from log and hooks \`git show\`.

`log`
:	Downloads last uploaded SHA1 from log and hooks \`git log\`.

`add-scope <scope>`
:	Creates a new scope (e.g. dev, production, testing, foobar).
	This is a wrapper action over git-config.
	See **SCOPES** section for more information.

`remove-scope <scope>`
:	Remove a scope.

`help`
:	Shows a help screen.

# OPTIONS

`-u [username]`, `--user [username]`
:	FTP login name. If no argument is given, local user will be taken.

`-p [password]`, `--passwd [password]`
:	FTP password. See `-P` for interactive password prompt.

`-P`, `--ask-passwd`
:	Ask for FTP password interactively.

`-k [[user]@[account]]`, `--keychain [[user]@[account]]`
:	FTP password from KeyChain (Mac OS X only).

`-a`, `--all`
:	Uploads all files of current Git checkout.

`-c`, `--commit`
:	Sets SHA1 hash of last deployed commit by option.

`-A`, `--active`
:	Uses FTP active mode. This works only if you have either no firewall
	and a direct connection to the server or an FTP aware firewall. If you
	don't know what it means, you probably won't need it.

`-b [branch]`, `--branch [branch]`
:	Push a specific branch

`-s [scope]`, `--scope [scope]`
:	Using a scope (e.g. dev, production, testing, foobar). See **SCOPE**
	and **DEFAULTS** section for more information.

`-l`, `--lock`
:	Enable remote locking.

`-D`, `--dry-run`
:	Does not upload or delete anything, but tries to get the `.git-ftp.log`
	file from remote host.

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
:	Specifies the remote root directory to deploy to.
	The remote path in the URL is ignored.

`--syncroot`
:	Specifies a local directory to sync from as if it were the git project
	root path.

`--key`
:	SSH private key file name for SFTP.

`--pubkey`
:	SSH public key file name. Used with --key option.

`--insecure`
:	Don't verify server's certificate.

`--cacert <file>`
:	Use <file> as CA certificate store.
	Useful when a server has a self-signed certificate.

`--disable-epsv`
:	Tell curl to disable the use of the EPSV command when doing passive FTP
	transfers.
	Curl will normally always first attempt to use EPSV before PASV,
	but with this option, it will not try using EPSV.

`--no-commit`
:	Stop while merging downloaded changes during the pull action.

`--changed-only`
:	During the ftp mirror operation during a pull command, consider only
	the files changed since the deployed commit.

`--no-verify`
:	Bypass the pre-ftp-push hook. See **HOOKS** section.

`--enable-post-errors`
:	Fails if post-ftp-push raises an error.

`--auto-init`
:	Automatically run init action when running push action

`--version`
:	Prints version.

`-x [protocol://]host[:port]`, `--proxy [protocol://]host[:port]`
:	Use the specified proxy. This option is passed to curl.
	See the curl manual for more information.

# URL

The scheme of an URL is what you would expect

	protocol://host.domain.tld:port/path

Below a full featured URL to *host.example.com* on port *2121* to path *mypath*
using protocol *ftp*:

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

# EXAMPLES

## FIRST UPLOADS

Upload your files to an FTP server the first time:

	$ git ftp init -u "john" -P "ftp://example.com/public_html"

It will authenticate with the username `john` and ask for the
password. By default, it tries to transfer data in EPSV mode.
Depending on the network and server configuration, that may fail.
You can try to add the `--disable-epsv` option to use the IPv4 passive FTP
connection (PASV). In rare circumstances, you can use `--active` for the
original FTP transfer mode. These options do not apply to SFTP.

You are less likely to face connection problems with SFTP.
But be aware of the different
handling of relative and absolute paths. If the directory `public_html` is in
the home directory on the server, then upload like this:

	$ git ftp init -u "john" --key "$HOME/.ssh/id_rsa" "sftp://example.com/~/public_html"

Otherwise it will use an absolute path, for example:

	$ git ftp init -u "john" --key "$HOME/.ssh/id_rsa" "sftp://example.com/var/www"

On some systems Git-ftp fails to verify the server's fingerprint.
You can then use the `--insecure` option to skip the verification.
That will leave you vulnerable to man-in-the-middle attacks, but is still more
secure than plain FTP.

Git-ftp guesses the path of the public key file corresponding to your private
key file. If you just have a private key, for example a .pem file, you need
Git-ftp version 1.3.4 and Curl version 7.39.0 or newer.
If you have an older version of Git-ftp or Curl, you can
create the public key with the ssh-keygen command:

	$ ssh-keygen -y -f key.pem > key.pem.pub

## RESET THE UPLOADED STATE

Many people already uploaded their files to the server.
If you want to mark the uploaded version as the same as your local branch:

	$ git ftp catchup

This example omits options like `--user`, `--password` and `url`.
See DEFAULTS below to learn how to store your configuration so that you don't
need to repeat it.

After you stored the commit id of the uploaded commit via `init` or
`catchup`, you can then upload any new commits:

	$ git ftp push

If you discovered a bug in the last uploaded version and you want to go back
by three commits:

	$ git checkout HEAD~3
	$ git ftp push

Or maybe some files got changed on the server and you want to upload all
changes between branch `master` and branch `develop`:

	$ git checkout develop         # This is the version which is uploaded.
	$ git ftp push --commit master # Upload changes compared to master.

# DEFAULTS

Don't repeat yourself. Setting config defaults for git-ftp in .git/config

	$ git config git-ftp.<(url|user|password|syncroot|cacert|keychain|...)> <value>

Everyone likes examples:

	$ git config git-ftp.user john
	$ git config git-ftp.url ftp.example.com
	$ git config git-ftp.password secr3t
	$ git config git-ftp.syncroot path/dir
	$ git config git-ftp.cacert caCertStore
	$ git config git-ftp.deployedsha1file mySHA1File
	$ git config git-ftp.insecure 1
	$ git config git-ftp.key ~/.ssh/id_rsa
	$ git config git-ftp.keychain user@example.com
	$ git config git-ftp.remote-root htdocs

After setting those defaults, push to *john@ftp.example.com* is as simple as

	$ git ftp push

# SCOPES

Need different config defaults per each system or environment? Use the so
called scope feature.

Useful if you use multi environment development. Like a development, testing
and a production environment.

	$ git config git-ftp.<scope>.<(url|user|password|syncroot|cacert)> <value>

So in the case below you would set a testing scope and a production scope.

Here we set the params for the scope "testing"

	$ git config git-ftp.testing.url ftp.testing.com:8080/foobar-path
	$ git config git-ftp.testing.password simp3l

Here we set the params for the scope "production"

	$ git config git-ftp.production.user manager
	$ git config git-ftp.production.url live.example.com
	$ git config git-ftp.production.password n0tThatSimp3l

Pushing to scope *testing* alias *john@ftp.testing.com:8080/foobar-path*
using password *simp3l*

	$ git ftp push -s testing

*Note:* The **SCOPE** feature can be mixed with the **DEFAULTS** feature.
Because we didn't set the user for this scope,
git-ftp uses *john* as user as set before in **DEFAULTS**.

Pushing to scope *production* alias *manager@live.example.com* using
password *n0tThatSimp3l*

	$ git ftp push -s production

*Hint:* If your scope name is identical with your branch name. You can skip the
scope argument, e.g. if your current branch is "production":

	$ git ftp push -s

You can also create scopes using the add-scope action.
All settings can be defined in the URL.
Here we create the *production* scope using add-scope

	$ git ftp add-scope production ftp://manager:n0tThatSimp3l@live.example.com/foobar-path

Deleting scopes is easy using the `remove-scope` action.

	$ git ftp remove-scope production

# IGNORING FILES TO BE SYNCED

Add patterns to `.git-ftp-ignore` and all matching file names will be ignored.
The patterns are interpreted as shell glob patterns since version 1.1.0.
Before version 1.1.0, patterns were interpreted as regular expressions.
Here are some glob pattern examples:

Ignoring everything in a directory named `config`:

	config/*

Ignoring all files having extension `.txt`:

	*.txt

Ignoring a single file called `foobar.txt`:

	foobar.txt

Ignoring Git related files:

	.gitignore
	*/.gitignore      # ignore files in sub directories
	*/.gitkeep
	.git-ftp-ignore
	.git-ftp-include
	.gitlab-ci.yml

# SYNCING UNTRACKED FILES

The `.git-ftp-include` file specifies intentionally untracked files that
Git-ftp should upload.
If you have a file that should always be uploaded, add a line beginning with !
followed by the file's name.
For example, if you have a file called VERSION.txt then add the following line:

	!VERSION.txt

If you have a file that should be uploaded whenever a tracked file changes, add
a line beginning with the untracked file's name followed by a colon and the
tracked file's name.
For example, if you have a CSS file compiled from an SCSS file then add the
following line:

	css/style.css:scss/style.scss

If you have multiple source files, you can add multiple lines for each of them.
Whenever one of the tracked files changes, the upload of the paired untracked
file will be triggered.

	css/style.css:scss/style.scss
	css/style.css:scss/mixins.scss

If a local untracked file is deleted, any change of a paired tracked file will
trigger the deletion of the remote file on the server.

All paths are usually relative to the Git working directory.
When using the `--syncroot` option, paths of tracked files
(right side of the colon) are relative to the set syncroot.
Example:

	# upload "html/style.css" triggered by html/style.scss
	# with syncroot "html"
	html/style.css:style.scss

If your *source* file is outside the syncroot,
prefix it with a / and define a path relative
to the Git working directory. For example:

	# upload "dist/style.css" with syncroot "dist"
	dist/style.css:/src/style.scss

It is also possible to upload whole directories.
For example, if you use a package manager like composer, you can upload all
vendor packages when the file composer.lock changes:

	vendor/:composer.lock

But keep in mind that this will upload all files in the vendor folder, even
those that are on the server already.
And it will not delete files from that directory if local files are deleted.

# DOWNLOADING FILES (EXPERIMENTAL)

**WARNING:** It can delete local untracked files that are not listed in your
`.git-ftp-ignore` file.

You can use git-ftp to download from the remote host into your repository.
You will need to install the lftp command line tool for that.

	git ftp download

It uses lftp's mirror command to download all files that are different on the
remote host. You can inspect the changes with git-diff.
But if you have some local commits that have not been uploaded to the remote
host, you may not compare to the right version.
You need to compare the downloaded files to the commit that was uploaded last.
This magic is done automatically by

	git ftp pull

It does the following steps for you:

	git checkout <remote-commit>
	git ftp download
	git add --all
	git commit -m '[git-ftp] remotely untracked modifications'
	git ftp catchup
	git checkout <my-branch>
	git merge <new-remote-commit>

If you want to inspect the downloaded changes before merging them into your
current branch, add the option `--no-commit`.
It will stop during the merge at the end of the pull action.
You can inspect the merge result first and can then decide to continue or
abort.

	git ftp pull --no-commit
	# inspect the result and commit them
	git commit
	# or abort the merge
	git merge --abort

If you abort the merge, the downloaded changes will stay in an unreferenced
commit until the Git garbage collector is run.
The commit id will be printed so that you can tag it or create a new branch.

# HOOKS (EXPERIMENTAL)

**This feature is experimental. The interface may change.**

Git-ftp supports client-side hook scripts during the init and the push action.

`pre-ftp-push` is called just before the upload to the server starts, but after
the changeset of files was generated. It can be bypassed with the --no-verify
option.

The hook is called with four parameters.
The first is the used scope or the host name if no scope is used.
The second parameter is the destination URL.
The third is the local commit id which is going to be uploaded and
the fourth is the remote commit id on the server which is going to be updated.

The standard input is a list of all filenames to sync. Each file is preceeded
by A or D followed by a space. A means that this file is scheduled for upload,
D means it's scheduled for deletion. All entries are separated by the NUL byte.
This list is different to git diff, because
it has been changed by the rules of the `.git-ftp-include` file and the
`.git-ftp-ignore` file.

Exiting with non-zero status from this script causes
Git-ftp to abort and exit with status 9.

An example script is:

```bash
#!/bin/bash
#
# An example hook script to verify what is about to be uploaded.
#
# Called by "git ftp push" after it has checked the remote status, but before
# anything has been pushed. If this script exits with a non-zero status nothing
# will be pushed.
#
# This hook is called with the following parameters:
#
# $1 -- Scope name if set or host name of the remote
# $2 -- URL to which the upload is being done
# $3 -- Local commit id which is being uploaded
# $4 -- Remote commit id which is on the server
#
# Information about the files which are being uploaded or deleted is supplied
# as NUL separated entries to the standard input in the form:
#
#   <status> <path>
#
# The status is either A for upload or D for delete. The path contains the
# path to the local file. It contains the syncroot if set.
#
# This sample shows how to prevent upload of files containing the word TODO.

remote="$1"
url="$2"
local_sha="$3"
remote_sha="$4"

while read -r -d '' status file
do
	if [ "$status" = "A" ]
	then
		if grep 'TODO' "$file"; then
			echo "TODO found in file $file, not uploading."
			exit 1
		fi
	fi
done

exit 0
```

`post-ftp-push` is called after the transfer has been finished. The standard
input is empty, but the parameters are the same as given to the `pre-ftp-push`
hook. This hook is **not** bypassed by the --no-verify option.
It is meant primarily for notification and its exit status does not have any
effect.

# NETRC

In the backend, Git-ftp uses curl.
This means `~/.netrc` could be used beside the other options of Git-ftp
to authenticate.

	$ editor ~/.netrc
	machine ftp.example.com
	login john
	password SECRET

# EXIT CODES

There are a bunch of different error codes and their corresponding error
messages that may appear during bad conditions.
At the time of this writing, the exit codes are:

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

`9`
:	The `pre-ftp-push` hook failed

`10`
:	A local file operation like `cd` or `mkdir` failed

# KNOWN ISSUES & BUGS

The upstream BTS can be found at <https://github.com/git-ftp/git-ftp/issues>.

[Git]: http://git-scm.org

# AUTHORS

Git-ftp was started by Rene Moser and is currently maintained by Maikel Linke.
Numerous conributions have come from Github users.
See the AUTHORS file for an incomplete list of contributors.
