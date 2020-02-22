# INSTALL

You can find instructions for:

- [Linux/Unix based systems using make](#linuxunix-based-systems-using-make)
- [Debian, Ubuntu and others using apt](#debian-ubuntu-and-others-using-apt)
- [ArchLinux](#archlinux-aur-unofficial)
- [MacOS](#macos)
- [Windows](#windows)


## Linux/Unix based systems using make

Note: Make sure Git and cURL are installed.

This should work on MacOS, Debian, Ubuntu, Fedora, RedHat, etc.

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

## Linux/Unix based systems using direct download

Another way is to download the shell script directly and place it in your `bin`
directory:

```sh
curl https://raw.githubusercontent.com/git-ftp/git-ftp/master/git-ftp > /bin/git-ftp
chmod 755 /bin/git-ftp
```

Maybe `sudo` is required to do this.
Please note that this will install the most recent version, even if its
unreleased. To install a specific version replace `master` with the version tag.

Uninstall:
```sh
rm /bin/git-ftp
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


## macOS

First, ensure you have installed Xcode and command line tools. Command line tools can be download at https://developer.apple.com/download/more/ or via command: 

```
xcode-select --install
```

Using homebrew:

```sh
brew install git
brew install brotli
brew install git-ftp
```

### SFTP on macOS

The default version of curl coming with macOS does not support SFTP (`Protocol sftp not supported or disabled in libcurl`).
So if you require SFTP support you can compile curl with SFTP support on your own.
First download a [curl source package](http://curl.haxx.se/download.html) from the website and unpack the archive.
Then you can start installing some dependencies and finally building curl:

```sh
cd /your/unpacked/archive

brew install openssl
brew install libssh2

./configure -q --with-libssh2 --with-ssl=/usr/local/opt/openssl
make
make install
```

To check the result you can run `curl --version`. This will give you some information about curl including a list of supported protocols.
In this list, `ftp`, `ftps`, `http`, `https` and of course `sftp` should be present.

It might happen that the default curl is still executed, because it is taking precedence over your custom build in `/usr/local/bin`.
You can fix this by adding `export PATH=/usr/local/bin:$PATH` to your `~/.bash_profile`.

_Thanks to Andrew Berls for the [original post](http://andrewberls.com/blog/post/adding-sftp-support-to-curl) on this._

## Windows

There are at least two ways to install git-ftp on Windows.

- Using Git for Windows, former msysgit (recommended)
- Using cygwin

### Git for Windows, former msysgit (recommended)

Install [Git for Windows](https://git-for-windows.github.io/).

If you require SFTP support you will need to [download curl](http://curl.haxx.se/download.html) for
Windows with SFTP support. Choose either the Win32 2000/XP MSI or Win64 2000/XP x86_64 MSI is recommended.
If you installed curl, then remove `bin/curl.exe` from your Git for Windows
installation directory. It will fall back to the newly installed version.

Find Git Bash in your start menu (or inside `C:\Program Files\Git`) and right-click to
choose "Run as Administrator". Then paste in the following two commands:

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
