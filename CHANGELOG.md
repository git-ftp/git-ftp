Version 1.0.2
=============

René Moser:
* Removed optimistic directory deletion, fixes GH-168 (reported by Justin Maier)

Version 1.0.1
=============

Maikel Linke (1):
* Fixed 'deployedsha1file' was not always considered

ysakmrkm:
* Docs: Add --remote-root to man file.

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
