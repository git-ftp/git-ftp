Version 0.8.3
=============

* Performance improvments in submodule handling. Thanks to Adam Brengesjö.
* Hotfix 0.8.2 did not fix the bug. Another try fixing bug related to ARG_MAX.
* Fixed bug 'egrep: repetition-operator operand invalid' if running on OSX 10.8.

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
