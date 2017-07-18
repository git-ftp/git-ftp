# INSTALL

You can find instructions for:

- [Linux/Unix based systems using make](#linuxunix-based-systems-using-make)
- [Debian, Ubuntu and others using apt](#debian-ubuntu-and-others-using-apt)
- [ArchLinux](#archlinux-aur-unofficial)
- [Mac OS X](#mac-os-x)
- [Windows](#windows)


## Linux/Unix based systems using make

Note: Make sure Git and cURL are installed.

This should work on Mac OS X, Debian, Ubuntu, Fedora, RedHat, etc.

The easiest way is to use Git for installing:

```sh
git clone https://github.com/git-ftp/git-ftp.git
cd git-ftp

# choose the newest release
tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"

# checkout the latest tag
git checkout "$tag"
sudo make install
```

Updating using git:

```sh
git fetch
git checkout "$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"
sudo make install
```


## Debian, Ubuntu and others using apt

At least Debian and Ubuntu provide git-ftp in their main repositories.

```sh
sudo apt-get install git-ftp
```

If you would like the newest release maintained by Git-ftp,
you can add the PPA:

```sh
sudo -s
add-apt-repository ppa:git-ftp/ppa

# On Debian, you need to modify the sources list to use the same PPA
source /etc/*-release
if [ "$ID" = "debian" ]; then
    dist="$(echo /etc/apt/sources.list.d/git-ftp-ppa-*.list | sed 's/^.*ppa-\(.*\)\.list$/\1/')"
    sed -i.backup "s/$dist/precise/g" /etc/apt/sources.list.d/git-ftp-ppa-*.list
fi

apt-get update
```


## ArchLinux (AUR: unofficial)

See https://aur.archlinux.org/packages/?O=0&C=0&SeB=nd&K=git-ftp&SB=v&SO=d&PP=50&do_Search=Go


## Mac OS X

Using homebrew:

```sh
brew install git
brew install curl --with-ssl --with-libssh2
brew install git-ftp
```

## Windows

There are at least two ways to install git-ftp on Windows.

- Using Git for Windows, former msysgit (recommended)
- Using cygwin

### Git for Windows, former msysgit (recommended)

Install [Git for Windows](https://git-for-windows.github.io/).
It comes with curl installed, but it doesn't support SFTP by default.
In order to use SFTP, [download curl](http://curl.haxx.se/download.html) for
Windows with SFTP support.
Win32 2000/XP MSI or Win64 2000/XP x86_64 MSI is recommended.
If you installed curl, then remove `bin/curl.exe` from your Git for Windows
installation directory. It will fall back to the newly installed version.

Finally, open the Git Bash which is located in `C:\Program Files (x86)\Git`
by default.

```bash
curl https://raw.githubusercontent.com/git-ftp/git-ftp/master/git-ftp > /bin/git-ftp
chmod 755 /bin/git-ftp
```

*Note: the `/bin` directory is an alias.
By default this is the same as `C:\Program Files (x86)\Git\usr\bin`.*

### cygwin

Install cygwin and install the package 'curl'.
Then open the cygwin console and install Git-ftp with the following commands:

```bash
curl https://raw.githubusercontent.com/git-ftp/git-ftp/master/git-ftp > /bin/git-ftp
chmod 755 /bin/git-ftp
```

### Git for Windows and cygwin both installed

If you have both Git for Windows and cygwin installed on Windows and want to
use Git for Windows for Git commands, you may get an error
"No such file or directory" for a path starting with "/cygdrive/", for example:

    creating `/cygdrive/c/TEMP/git-ftp-m7GH/delete_tmp': No such file or directory

The problem is that Git-ftp use commands from both Git for Windows and cygwin
directories. But by default, cygwin is configured to start paths with the
prefix "/cygdrive" while Git for Windows starts paths with "/".
To fix the problem, open file "<cygwin>\etc\fstab"
(e.g. "c:\cygwin\etc\fstab") and change parameter "/cygwin/" to "/", for example:

    # This is default:
    none /cygdrive/ cygdrive binary,posix=0,user 0 0

change to:

    # This is changed:
    none / cygdrive binary,posix=0,user 0 0

After this, close all console windows and try again.
