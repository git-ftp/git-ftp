Version 1.3.1
=============

* Fixed man file to avoid pandoc bug resulting in missing content

Version 1.3.0
=============

* FTPES support for submodules
* Fix submodule bugs by quoting argument correctly
* Include algorithm is now independent of ignore list
* Include algorithm reads leading `/` as root of the repository like Git
* Support for `pre-ftp-push` and `post-ftp-push` hooks
* Performance improvements in generating file list
* Allow file names to start with `-`
* New `--changed-only` parameter for pull action
* New "snapshot" action
* Improved test setup comes with vsftpd configuration file

Version 1.2.0-rc.1
==================

File selecting:
* Consider .git-ftp-include even if no files changed
* Let curl encode file names
* Separate filenames by nul instead of newline
* Using --diff-filter to list added/changed/deleted files

Submodules:
* Suppress submodule status error message of git v2.7
* Ignore uninitialised submodules

New features:
* Pull feature
* Download feature using lftp

Version 1.1.0-rc.1
==================

Benjamin Marguin:
* Fixed submodule upload with multiple submodules.

Hugo Laloge (laloge_h)
* Added option to push specific branch.

Alex Hoppen:
* Added keychain config.

Maikel Linke (mkllnk):
* Added upload and delete buffers in a curl config file.
* Added optimisation in include file processing.
* Added filtering with shell glob patterns instead of regex.
* Added encoding remote file path for curl.
* Added misc minor improvements and code optimisations.
* Docs: Explaining .git-ftp-ignore patterns.
* Fixed Mac OS X compatibility issues.
* Added mktemp alternative.
* Added catchup of submodules.

Tim:
* Added URL encoding username and password to be used in curl URL.

ysakmrkm:
* Docs: Add --remote-root to man file.

René Moser:
* Added -P for interactive password prompt, use -p only for passing password by cli.
* Added functionality for using temporary directory for temp files.
* Docs: Updated man page and docs about -P.
* Removed optimistic directory deletion, fixes GH-168 (reported by Justin Maier)

Version 1.0.0
=============

Maikel Linke (mkllnk):
* Added test to ignore single file in root directory.
* Added Travis support.
* Added tests for git-ftp-include with git-ftp-ignore.
* Added test uploading heaps.
* Improved and extended testing.
* Improved checking remote access before initial upload.
* Fixed upload_sha1 at end of push action.
* Fixed not recognizing different SHA1 object.
* Fixed upload local sha1 only if files where pushed.
* Fixed delete buffer. Fire before ARG_MAX reached.
* Fixed counting bug in handle_file_sync().
* Fixed upload buffer length check.
* Fixed prevent deleting of unversioned files.
* Removed duplicate code of setting curl args.

Andrew Minion, Szerémi Attila, Max Horn, Ryan Ponce, Rob Upcraft, Pablo Alejandro Fiumara:
* Documentation updates.

René Moser:
* Fixed scope may not contain spaces
* Fixed error level of failing delete action.
* Several improvements.

Sudaraka Wijesinghe:
* Fix for url from git config not being identified correctly.

Matteo Manchi:
* Fixed DEPLOYED_SHA1_FILE now cares about scope.

iKasty:
* Added support for different remote root directory, option --remote-root.

Brad Jones:
* Fixed delete for SFTP.

Version 1.0.0-rc.2
==================

Maikel Linke (mkllnk):
* Added more tests, tests clean up and improvements. See README.md in /tests.
* Improved docs.

Jason Woof, mkllnk:
* Fixed .git-ftp-include split lines on whitespace.
* Fixed .git-ftp-include will not upload files that are a substr of another path being uploaded.

René Moser:
* Added netrc in docs.
* Fixed sha1 not updated if amended.

Version 1.0.0-rc.1
==================

Moz Morris:
* Delete files using a single connection.

m4grio:
* Added --disable-epsv option.

Martin Hradil:
* Support for .git-ftp-including files without any git dependencies.

René Moser:
* Updated docs.
* Fixed git init fails when using .git-ftp-include as SHA1_DEPLOYED is defined.
* Code cleanup.

Version 0.9.0
=============

Adam Brengesjö:
* Add action 'log'.

Jason Woofenden:
* Fixed quoting of REMOTE_PASSWD.
* Fixed detection of curl verbosity setting.
* Fixed log deletion failure even when being verbose.

Joyce Babu:
* Public key authentication key files path as configurable option.
* Renamed the parameter names to match curl options.
Louis Li:
* Fixed a minor formatting issue in INSTALL.

Mar Cejas:
* Fixed bug, Error: binary operator expected.

Shea Bunge:
* Doc: Updated Windows installation instructions.

mamzellejuu:
* Doc: Fixed Repo path wasn't updated.

René Moser:
* Fixed egrep: repetition-operator operand invalid OS X 10.9

Version 0.8.4
=============

* Performance improvments in submodule handling. Thanks to Adam Brengesjö.
* Hotfix 0.8.2 did not fix the bug. Another try fixing bug related to ARG_MAX.
* Info for OS X 10.8 users: Make sure you are using GNU grep. See commit f4baf02731ada267d399a6206d21fffc0357d75a.
* Info: Repo moved to https://github.com/git-ftp/git-ftp
* Added support for syncing untracked files. Thanks to Jonathan Patt.
* Added support for --insecure in config. Thanks to Erik Erkelens.
* Fixed issues with insecure config option being ignored. Thanks to Andrew Fenn.
* Fixed error output not using stderr.
* Fixed sync root missing from submodule sync. Thanks to John Learn.
* Lots of minor fixes and documentation updates.

Version 0.8.2
=============

* Hotfixed bug, string length buffer was too small. This could cause the file upload to fail.

Version 0.8.1
=============

* Added feature, --scope without argument takes the current branch name as scope. Thanks to Chris J. Lee.
* Fixed bug, respect ARG_MAX if there is a large number of files.
* Fixed bug, local locking did not work correctly with submodule handilng. Removed.
* Added feature --insecure to not verify server certificate. Thanks to Łukasz Stelmach.
* Added feature --cacert to provide custom cacert. Thanks to Łukasz Stelmach.

Version 0.8.0
=============

* Fixed bug, DEFAULTS config are not over-writeable by SCOPES config using emtpy string. Thanks to Ingo Migliarina.
* Fixed long outstanding issue, using a single connection for all uploads now. This makes git-ftp 5x faster!
* Fixed bug, respect syncroot while syncing a submodule. Thanks to https://github.com/escaped.
* Added feature, show error log at the end.

Version 0.7.5
=============

* Updated man page.
* Fixed bug, check for dirty repository was dependent on english.

Version 0.7.4
=============

* Code cleanup.
* Fixed bug in add-scope action, related to OS X only.

Version 0.7.3
=============

* Added add-scope and remove-scope actions.
* .git-ftp-ignore can now contain comments (#...) and whitespaces.
* Fixed bug if path to git project contains whitespaces.
* Fixed bug in syncroot feature.
* Removed parallel connections feature.
* Code cleanup (syncroot).
