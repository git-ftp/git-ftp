Testing Environment
===================

The tests require access to an FTP server.
They need full access to create, read and delete directories and files.
You can provide the account data via environment variables.

    $ GIT_FTP_USER=kate
    $ GIT_FTP_PASSWD=s3cret
    $ GIT_FTP_ROOT=localhost/test_dir/   # trailing slash!
    $ export GIT_FTP_USER
    $ export GIT_FTP_PASSWD
    $ export GIT_FTP_ROOT

Run the unit tests by executing `make`.

    $ make

If you don't have [lftp] installed, the test will leave a bunch of test directories on the server.
They are all named like git-ftp-XXXX.
You should delete them.

[lftp]: http://lftp.yar.ru/
