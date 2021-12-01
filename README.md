Git-ftp -- uploads to FTP servers the Git way
=============================================

If you use Git and you need to upload your files to an FTP server,
Git-ftp can save you some time and bandwidth by uploading only those files that
changed since the last upload.

It keeps track of the uploaded files by storing the commit id
in a log file on the server. It uses Git to determine which local
files have changed.

You can easily deploy another branch or go back in the Git history to upload
an older version.

```sh
# Setup
git config git-ftp.url "ftp://ftp.example.net:21/public_html"
git config git-ftp.user "ftp-user"
git config git-ftp.password "secr3t"

# Upload all files
git ftp init

# Or if the files are already there
git ftp catchup

# Work and deploy
echo "new content" >> index.txt
git commit index.txt -m "Add new content"
git ftp push
# 1 file to sync:
# [1 of 1] Buffered for upload 'index.txt'.
# Uploading ...
# Last deployment changed to ded01b27e5c785fb251150805308d3d0f8117387.

# Or: To avoid 1000 commits per change...
git ftp dirty-upload
```

If you encounter any problems, add the `-v` or `-vv` option to see more output.
The manual may answer some of your questions as well.

Further Reading
---------------

* Read the [manual](man/git-ftp.1.md) for more options, features and examples.
* See the [installation instructions](INSTALL.md) for your system.
* Checkout the [changelog](CHANGELOG.md).
* Check [git-ftp issues on GitHub] for open issues.
* Follow this project on twitter [@gitftp].

* Deploy with [git-ftp and GitHub Actions](https://github.com/marketplace/actions/ftp-deploy)
* Deploy with [git-ftp and Bitbucket Pipelines](https://www.youtube.com/watch?v=8HZhHtZebdw) (video tutorial).

Limitations
-----------

* Windows and OS X: I am very limited in testing on Windows and OS X. Thanks
  for helping me out fixing bugs on these platforms.
* git-ftp as deployment tool: git-ftp was not designed as centralized
  deployment tool. While a commit is being pushed and uploaded to the FTP
  server, all files belonging to that revision must remain untouched until
  git-ftp has successfully finished the upload. Otherwise, the contents of the
  uploaded file will not match the contents of the file referenced in the
  commit.

Contributions
-------------

Don't hesitate to improve this tool.
Don't forget to add yourself to the [AUTHORS](AUTHORS) file.
The core functionality is unit tested using shunit2.
You can find the tests in `tests/`.

Copyright
---------

This application is licensed under [GNU General Public License, Version 3.0]

[git-ftp issues on GitHub]: http://github.com/git-ftp/git-ftp/issues
[GNU General Public License, Version 3.0]:
 http://www.gnu.org/licenses/gpl-3.0-standalone.html
[@gitftp]: https://twitter.com/gitftp
