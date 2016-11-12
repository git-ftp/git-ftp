Testing Environment
===================

The tests require access to an FTP server. You can start one locally.
Two binaries for linux and osx are in this directory. The linux binary was compiled on a Debian 7 Wheezy system with:

```sh
wget https://security.appspot.com/downloads/vsftpd-3.0.3.tar.gz
tar xzf vsftpd-3.0.3.tar.gz
cd vsftpd-3.0.3
make
```

The tests need full permissions to create, read and delete directories and files.
You can provide the account data via environment variables.

```sh
GIT_FTP_HOST=localhost
GIT_FTP_PORT=:2121	# the colon `:` is important
GIT_FTP_ROOT=test_dir
GIT_FTP_USER=kate
GIT_FTP_PASSWD=s3cret
export GIT_FTP_HOST
export GIT_FTP_PORT
export GIT_FTP_ROOT
export GIT_FTP_USER
export GIT_FTP_PASSWD
```

Run the unit tests by executing `make`.

```sh
make
```

If you don't have [lftp] installed, the test will leave a bunch of test directories on the server.
They are all named like git-ftp-XXXX.
You should delete them.

[lftp]: http://lftp.yar.ru/
